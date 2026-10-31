#!/usr/bin/env node
/*
 * Render every Argo CD ApplicationSet in a checkout to plain manifests.
 *
 *   render-apps.js render <repo-root> <out-dir>   render all apps, one file per resource
 *   render-apps.js diff <base-out> <head-out> [max-chars]   markdown diff of two renders
 *
 * Mirrors what Argo CD does for this repo: ApplicationSets are evaluated with
 * jsonnet, expanded per argo/clusters/*.yaml, and each source is rendered with
 * Helm or with the Tanka CMP flow (see ansible .../services/tasks/argocd.yml).
 * Output is canonicalized with yq (sorted keys) so Helm and Tanka renders compare.
 * Needs node, jsonnet, helm, yq, tk, jb and diff on PATH, plus network access
 * for charts. No secrets are read; encrypted files are never touched.
 */
'use strict';

const { spawn, spawnSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const TEMPLATE_RE = /\{\{\s*(?:index\s+)?\.([\w.]+)(?:\s+"([^"]+)")?\s*\}\}/g;
const CONCURRENCY = 4;

function run(cmd, args, { cwd, env, input } = {}) {
  return new Promise((resolve, reject) => {
    const p = spawn(cmd, args, { cwd, env, stdio: [input === undefined ? 'ignore' : 'pipe', 'pipe', 'pipe'] });
    if (input !== undefined) {
      // The child may exit before reading everything; its stderr explains why.
      p.stdin.on('error', () => {});
      p.stdin.end(input);
    }
    let out = '';
    let err = '';
    p.stdout.on('data', (d) => (out += d));
    p.stderr.on('data', (d) => (err += d));
    p.on('error', reject);
    p.on('close', (code) => {
      if (code !== 0) reject(new Error(`${cmd} ${args.join(' ')}\n${err.trim()}`));
      else resolve(out);
    });
  });
}

// Resolve ApplicationSet go-template references like {{ .cluster }}.
function subst(node, params) {
  if (typeof node === 'string') {
    return node.replace(TEMPLATE_RE, (whole, dotted, key) => {
      const parts = dotted.split('.');
      if (key) parts.push(key);
      let cur = params;
      for (const p of parts) {
        if (cur === null || typeof cur !== 'object' || !(p in cur)) return whole;
        cur = cur[p];
      }
      return String(cur);
    });
  }
  if (Array.isArray(node)) return node.map((n) => subst(n, params));
  if (node && typeof node === 'object') {
    return Object.fromEntries(Object.entries(node).map(([k, v]) => [k, subst(v, params)]));
  }
  return node;
}

const mkTmp = () => fs.mkdtempSync(path.join(os.tmpdir(), 'render-apps-'));

// Ignore locally added repos so dependency indexes are always fetched fresh.
function helmEnv(tmp) {
  return { ...process.env, HELM_REPOSITORY_CONFIG: path.join(tmp, 'repositories.yaml') };
}

function helmArgs(src, root, tmp, namespace) {
  const h = src.helm || {};
  const args = [h.releaseName || 'release', null, '--namespace', namespace, '--include-crds'];
  for (const vf of h.valueFiles || []) {
    const p = vf.replace('$values', root);
    if (fs.existsSync(p)) args.push('-f', p);
  }
  if (h.valuesObject && Object.keys(h.valuesObject).length) {
    const vo = path.join(tmp, 'valuesObject.json');
    fs.writeFileSync(vo, JSON.stringify(h.valuesObject));
    args.push('-f', vo);
  }
  return args;
}

async function renderHelm(src, root, namespace) {
  const tmp = mkTmp();
  try {
    const env = helmEnv(tmp);
    const args = helmArgs(src, root, tmp, namespace);
    if (src.chart) {
      const { chart, repoURL: repo, targetRevision: ver } = src;
      args[1] = chart;
      if (/^https?:\/\//.test(repo)) {
        args.push('--repo', repo, '--version', ver);
      } else {
        let ref = repo.startsWith('oci://') ? repo : `oci://${repo}`;
        ref = ref.replace(/\/+$/, '');
        if (ref.split('/').pop() !== chart) ref += `/${chart}`;
        args[1] = ref;
        args.push('--version', ver);
      }
      return await run('helm', ['template', ...args], { env });
    }
    // Local chart: build deps in a copy so the checkout stays clean.
    const chartDir = path.join(tmp, 'chart');
    fs.cpSync(path.join(root, src.path), chartDir, { recursive: true });
    if (fs.readFileSync(path.join(chartDir, 'Chart.yaml'), 'utf8').includes('dependencies')) {
      await run('helm', ['dependency', 'update', chartDir], { env });
    }
    args[1] = chartDir;
    return await run('helm', ['template', ...args], { env });
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
}

async function renderTanka(src, root) {
  const env = Object.fromEntries(src.plugin.env.map((e) => [e.name, e.value]));
  const tmp = mkTmp();
  try {
    const app = path.join(tmp, 'app');
    fs.cpSync(path.join(root, src.path), app, { recursive: true });
    fs.rmSync(path.join(app, 'vendor'), { recursive: true, force: true });
    await run('jb', ['install'], { cwd: app });
    const ns = env.TANKA_NAMESPACE;
    fs.writeFileSync(
      path.join(app, 'spec.json'),
      JSON.stringify({
        apiVersion: 'tanka.dev/v1alpha1',
        kind: 'Environment',
        metadata: { name: `${env.TANKA_CLUSTER}/${ns}/${env.TANKA_APP}` },
        spec: { apiServer: env.TANKA_APISERVER, namespace: ns },
      }),
    );
    fs.renameSync(path.join(app, 'main.jsonnet'), path.join(app, '_main.jsonnet'));
    fs.writeFileSync(
      path.join(app, 'main.jsonnet'),
      `(import "_main.jsonnet") + ${env.TANKA_OVERRIDES || '{}'}\n`,
    );
    return await run('tk', ['show', '.', '--dangerous-allow-redirect'], { cwd: app });
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
}

// Helm keeps template key order and quoting, Tanka emits sorted keys, so the same
// resource renders differently depending on the tool. Re-emit every document with
// sorted keys, no comments and no explicit scalar styles so only real changes show
// in the diff. Also:
//  - YAML embedded in ConfigMap data (*.yaml / *.yml) gets the same treatment, as
//    Helm's toYaml and jsonnet's manifestYamlDoc format it differently.
//  - Namespaced resources without metadata.namespace (Helm leaves it to the
//    destination, Tanka may set it) get the application's namespace, so every
//    resource is identified by namespace + name on both sides.
// Lists keep their order, as it is significant to Kubernetes.
const CLUSTER_SCOPED = [
  'APIService', 'ClusterIssuer', 'ClusterRole', 'ClusterRoleBinding', 'ClusterSecretStore',
  'ClusterExternalSecret', 'CustomResourceDefinition', 'IngressClass', 'MutatingWebhookConfiguration',
  'Namespace', 'Node', 'PersistentVolume', 'PriorityClass', 'StorageClass',
  'ValidatingWebhookConfiguration', 'VolumeSnapshotClass',
];
const EMBEDDED_YAML =
  '(select(.kind == "ConfigMap") | .data.[] | select(key | test("\\.ya?ml$"))) |= ' +
  '(from_yaml | sort_keys(..) | ... style="" | to_yaml | trim) | ';
const CANONICAL =
  `(select(.metadata != null and .metadata.namespace == null and (${CLUSTER_SCOPED.map((k) => `.kind != "${k}"`).join(' and ')})) | .metadata.namespace) = strenv(RENDER_NAMESPACE) | ` +
  'sort_keys(..) | ... style="" | ... comments=""';

async function canonicalize(text, namespace) {
  const env = { ...process.env, RENDER_NAMESPACE: namespace };
  try {
    return await run('yq', ['-P', EMBEDDED_YAML + CANONICAL, '-'], { input: text, env });
  } catch {
    // Some ConfigMap *.yaml values are templates, empty or multi-document and do not
    // parse; keep them verbatim rather than failing the whole application.
    return run('yq', ['-P', CANONICAL, '-'], { input: text, env });
  }
}

function splitDocs(text) {
  // Drop comment-only / empty documents (helm "# Source:" headers).
  return text
    .split(/^---[ \t]*$/m)
    .filter((d) => d.split('\n').some((l) => l.trim() && !l.trimStart().startsWith('#')))
    .map((d) => `${d.replace(/^\n+|\n+$/g, '')}\n`);
}

const unquote = (s) => s.trim().replace(/^["']|["']$/g, '');

function docId(doc) {
  const top = (key) => {
    const m = doc.match(new RegExp(`^${key}:[ \\t]*(.+?)[ \\t]*$`, 'm'));
    return m ? unquote(m[1]) : null;
  };
  let name = null;
  let ns = null;
  const meta = doc.match(/^metadata:[ \t]*\n((?:[ \t]+.*\n?|\n)*)/m);
  if (meta) {
    const n = meta[1].match(/^ {2}name:[ \t]*(.+?)[ \t]*$/m);
    const s = meta[1].match(/^ {2}namespace:[ \t]*(.+?)[ \t]*$/m);
    name = n ? unquote(n[1]) : null;
    ns = s ? unquote(s[1]) : null;
  }
  const parts = [top('kind') || 'unknown', ns, name || 'unnamed'].filter(Boolean);
  return `${parts.join('.').replace(/[^A-Za-z0-9._-]+/g, '_')}.yaml`;
}

// Redact Secret values and ha-data mixin ConfigMaps (diffs get posted publicly), and checksum annotations
// that change on every render because charts feed random values into them.
function normalize(doc) {
  doc = doc.replace(/^([ \t]+checksum\/[\w.-]+:[ \t]*).+$/gm, '$1<checksum>');
  // ha-mixins-* ConfigMaps carry the private ha-data repo's rendered config.
  const isMixins = /^kind:[ \t]*ConfigMap[ \t]*$/m.test(doc) && /^ {2}name:[ \t]*ha-mixins-/m.test(doc);
  if (!isMixins && !/^kind:[ \t]*Secret[ \t]*$/m.test(doc)) return doc;
  const out = [];
  let section = false;
  let skipping = false;
  for (const line of doc.split('\n')) {
    if (/^(data|stringData):[ \t]*$/.test(line)) section = true;
    else if (/^\S/.test(line)) section = false;
    const m = section && line.match(/^( {2}[^\s#][^:]*:)[ \t]*\S?/);
    if (m) {
      out.push(`${m[1]} <redacted>`);
      skipping = true;
      continue;
    }
    if (skipping && /^ {3,}\S|^\s*$/.test(line)) continue; // block scalar continuation
    skipping = false;
    out.push(line);
  }
  return `${out.join('\n').replace(/\n+$/, '')}\n`;
}

function writeApp(out, appName, docs) {
  const dir = path.join(out, appName);
  fs.mkdirSync(dir, { recursive: true });
  const seen = {};
  for (const raw of docs) {
    const doc = normalize(raw);
    let fn = docId(doc);
    seen[fn] = (seen[fn] || 0) + 1;
    if (seen[fn] > 1) fn = fn.replace('.yaml', `.${seen[fn]}.yaml`);
    fs.writeFileSync(path.join(dir, fn), doc);
  }
}

async function renderApplication(app, root, out) {
  const name = app.metadata.name;
  const ns = app.spec.destination.namespace;
  try {
    const docs = [];
    for (const src of app.spec.sources) {
      if (src.ref && !src.path && !src.chart) continue;
      const text = src.plugin ? await renderTanka(src, root) : await renderHelm(src, root, ns);
      docs.push(...splitDocs(await canonicalize(text, ns)));
    }
    writeApp(out, name, docs);
    return [name, null];
  } catch (e) {
    // Keep going; the per-app failure is reported in the diff.
    fs.mkdirSync(path.join(out, name), { recursive: true });
    fs.writeFileSync(path.join(out, name, '_RENDER_ERROR.txt'), `${e.message}\n`);
    return [name, e.message];
  }
}

async function pool(items, limit, fn) {
  const results = new Array(items.length);
  let next = 0;
  const worker = async () => {
    while (next < items.length) {
      const i = next++;
      results[i] = await fn(items[i]);
    }
  };
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, worker));
  return results;
}

async function render(rootArg, outArg) {
  const root = path.resolve(rootArg);
  const out = path.resolve(outArg);
  fs.rmSync(out, { recursive: true, force: true });
  fs.mkdirSync(out, { recursive: true });

  const clusterDir = path.join(root, 'argo/clusters');
  const clusters = [];
  for (const f of fs.readdirSync(clusterDir).filter((f) => f.endsWith('.yaml')).sort()) {
    clusters.push(JSON.parse(await run('yq', ['-o=json', '.', path.join(clusterDir, f)])));
  }

  const apps = [];
  const appsetDir = path.join(root, 'argo/appsets');
  for (const f of fs.readdirSync(appsetDir).filter((f) => f.endsWith('.jsonnet')).sort()) {
    const appset = JSON.parse(await run('jsonnet', [path.join(appsetDir, f)], { cwd: root }));
    if (appset.kind !== 'ApplicationSet') continue;
    for (const params of clusters) apps.push(subst(appset.spec.template, params));
  }

  const results = await pool(apps, CONCURRENCY, (a) => renderApplication(a, root, out));
  const failed = results.filter(([, e]) => e);
  for (const [n, e] of failed) console.error(`FAILED ${n}: ${e}`);
  console.log(`rendered ${results.length - failed.length}/${results.length} applications`);
  return failed.length ? 1 : 0;
}

function walk(dir, base = dir, acc = {}) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, base, acc);
    else if (/\.(yaml|txt)$/.test(e.name)) acc[path.relative(base, p).split(path.sep).join('/')] = fs.readFileSync(p, 'utf8');
  }
  return acc;
}

// Unified diff via the system diff; headers are rewritten to base/ and head/.
function unified(oldText, newText, fromLabel, toLabel, tmp) {
  const a = path.join(tmp, 'a');
  const b = path.join(tmp, 'b');
  fs.writeFileSync(a, oldText || '');
  fs.writeFileSync(b, newText || '');
  const r = spawnSync('diff', ['-U3', a, b], { encoding: 'utf8', maxBuffer: 1 << 28 });
  if (r.status !== 0 && r.status !== 1) throw new Error(`diff failed: ${r.stderr}`);
  const lines = r.stdout.split('\n').slice(2); // drop temp-file header
  while (lines.length && lines[lines.length - 1] === '') lines.pop();
  return [`--- ${fromLabel}`, `+++ ${toLabel}`, ...lines];
}

function diff(baseOut, headOut, limit) {
  const a = walk(path.resolve(baseOut));
  const b = walk(path.resolve(headOut));
  const files = [...new Set([...Object.keys(a), ...Object.keys(b)])].sort();
  const apps = [...new Set(files.map((f) => f.split('/')[0]))];
  const tmp = mkTmp();
  const summary = [];
  const sections = [];
  try {
    for (const app of apps) {
      let added = 0;
      let removed = 0;
      let changed = 0;
      const body = [];
      for (const f of files.filter((f) => f.split('/')[0] === app)) {
        const oldText = a[f];
        const newText = b[f];
        if (oldText === newText) continue;
        if (oldText === undefined) added++;
        else if (newText === undefined) removed++;
        else changed++;
        body.push(
          ...unified(
            oldText,
            newText,
            oldText === undefined ? '/dev/null' : `base/${f}`,
            newText === undefined ? '/dev/null' : `head/${f}`,
            tmp,
          ),
        );
      }
      if (body.length) {
        summary.push(`| \`${app}\` | +${added} | ~${changed} | -${removed} |`);
        sections.push([app, body.join('\n')]);
      }
    }
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }

  if (!sections.length) return '### Rendered manifest diff\n\nNo changes to rendered manifests.\n';
  const out = [
    '### Rendered manifest diff',
    '',
    'What Argo CD would apply, rendered from the base and head commits (resources added / changed / removed).',
    '',
    '| Application | Added | Changed | Removed |',
    '|---|---|---|---|',
    ...summary,
    '',
  ];
  let used = out.reduce((n, l) => n + l.length + 1, 0);
  for (const [app, body] of sections) {
    const block = `<details><summary><code>${app}</code></summary>\n\n\`\`\`diff\n${body}\n\`\`\`\n\n</details>\n`;
    if (used + block.length > limit) {
      out.push(
        `_\`${app}\` and later diffs omitted: comment size limit. See the workflow summary or artifact for the full diff._`,
      );
      break;
    }
    out.push(block);
    used += block.length;
  }
  return `${out.join('\n')}\n`;
}

async function main(argv) {
  const [cmd, ...rest] = argv.slice(2);
  if (cmd === 'render' && rest.length === 2) return render(rest[0], rest[1]);
  if (cmd === 'diff' && rest.length >= 2) {
    process.stdout.write(diff(rest[0], rest[1], rest[2] ? parseInt(rest[2], 10) : Infinity));
    return 0;
  }
  console.error(
    'usage: render-apps.js render <repo-root> <out-dir>\n' +
      '       render-apps.js diff <base-out> <head-out> [max-chars]',
  );
  return 2;
}

main(process.argv).then(
  (code) => process.exit(code),
  (e) => {
    console.error(e);
    process.exit(1);
  },
);
