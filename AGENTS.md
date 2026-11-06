# Agent Guide

This repository is a personal homelab. Treat it as both real infrastructure and
an experimentation space: changes should be practical, reversible where possible,
and aligned with the existing patterns rather than polished into a generic
platform.

## Secret Handling

- `*.secret.yml` files are encrypted with `git-crypt` via `.gitattributes`.
- Do not read, print, summarize, copy, upload, or transmit the contents of
  encrypted secret files.
- It is acceptable to notice secret filenames and references to Kubernetes
  secret names or keys in non-secret manifests.
- If a task requires changing a secret, ask the user to make or confirm the
  secret-side edit. Do not invent placeholder secret values in encrypted files.
- Preserve `no_log: true` around secret-bearing Ansible tasks.
- Never add plaintext credentials, tokens, private keys, kubeconfigs, or
  service secrets to non-secret files.

## Project Shape

- `ansible/` bootstraps machines and the k3s cluster.
- `ansible/site.yml` imports the basic host setup and k3s install playbooks.
- `ansible/inventory/<cluster>/` contains cluster inventory and group vars.
- `clusters/` defines Flux itself. `clusters/environments/<cluster>/main.jsonnet`
  is a one-liner calling `clusters/lib/flux.libsonnet`, which also pins the Flux
  version. Shared Jsonnet deps live in `clusters/jsonnetfile.json`.
- `apps/` holds apps deployed by Flux (the way new apps are added). See
  "Flux Apps" below.
- `argo/` is the legacy Argo CD setup, being migrated to `apps/`. It contains
  ApplicationSet definitions and app values.
- `argo/clusters/*.yaml` describes clusters consumed by ApplicationSet git
  generators.
- `argo/appsets/*.jsonnet` defines one ApplicationSet per app or app group.
- `argo/lib/*.libsonnet` holds shared Jsonnet helpers for ApplicationSets,
  Helm sources, ingress, and env vars.
- `argo/apps/<app>/` contains Helm values and, for local charts, templates.
  Tanka-based apps (identified by `jsonnetfile.json`) use Jsonnet to generate
  Kubernetes manifests and may contain `spec.json`, `main.jsonnet`, and
  `vendor/`.
- `charts/extra-objects/` is a tiny helper chart for app-specific raw Kubernetes
  objects supplied through `extra.values.yaml`.
- `charts/infra/` renders Argo CD `Application` resources from values.
- `scripts/render-flux.sh` renders Flux and all apps for a cluster into the
  layout of the `homelab-manifests` repository.
- `.github/workflows/` runs Renovate, Ansible, and Flux render workflows.

The current cluster represented in the repo is `bet1`, with cluster metadata in
`argo/clusters/bet1.yaml` and Ansible inventory in
`ansible/inventory/bet1/hosts.ini`.

## Tooling

Tool versions are managed by `mise` in `.tool-versions`.

Common setup:

```sh
mise install
```

Primary tools currently pinned include Helm, kubectl, yq, kubectx, and
go-jsonnet.

## Ansible Notes

- Run Ansible from the `ansible/` directory unless a workflow says otherwise.
- `site.yml` is the main entrypoint for bootstrapping a cluster.
- `playbooks/install_basic.yml` installs baseline host tooling.
- `playbooks/install_k3s.yml` runs prerequisites, downloads k3s, installs the
  master and node roles, then installs base Kubernetes services.
- Base k3s service tasks are split into namespaces, secrets, Flux,
  dex, ingress, Argo CD, and extra CRDs.
- The Flux task (`tags: k8s_flux, never`) renders `clusters/environments/<cluster>`
  with `scripts/render-flux.sh` and applies Flux's components and sync config. It
  only runs on request and needs `jsonnet`, `jb`, `yq`, and `flux` locally. The
  `flux-system` git credentials come from `k8s_secrets` via the secrets task.
- Ansible's long-term scope is hosts, k3s, and seeding Flux. Everything else moves
  to Flux, and shared secrets are fanned out by External Secrets.
- The inventory currently uses `root` over SSH and groups hosts into `master`,
  `node`, `k3s_cluster`, and `storage`.

Example local command shape:

```sh
cd ansible
ansible-playbook -i inventory/bet1/hosts.ini site.yml
```

Be careful with commands that contact real machines or the live cluster. Prefer
dry validation and manifest rendering when possible, and call out any live
operation explicitly.

## Flux Apps

Flux is the target deployment system; Argo CD is legacy and will be removed.
Flux reads rendered manifests from the separate `homelab-manifests` repository
(`VoyTechnology/homelab-manifests`), which the `Render Flux` workflow writes on
merge to `main`. Never edit that repository by hand.

Layout in this repo (every app is a Tanka application):

```text
apps/
  jsonnetfile.json          shared deps (external-secrets, k8s and home-libsonnet)
  <app>/
    main.libsonnet          merges the app's mixin files, shared by all clusters
    config.libsonnet        every `_config+::` default of the app
    images.libsonnet        `_images+::` pins, bumped by Renovate
    <concern>.libsonnet     one responsibility each (see below)
    environments/<cluster>/
      main.jsonnet          extends ../../main.libsonnet with per-cluster `_config+::`
      spec.json             Tanka Environment (committed, unlike the Argo apps')
```

Rules:

- Each `environments/<cluster>` is a Tanka environment whose output is the app's
  Kubernetes objects. `scripts/render-flux.sh` runs `tk export` on every one and
  writes `apps/<cluster>/<app>/` in `homelab-manifests`, plus a Flux `Kustomization`
  in `clusters/<cluster>/apps/<app>.yaml` that it generates (do not write one).
- Build objects with the generated libraries directly (`external-secrets-libsonnet`,
  `k8s-libsonnet`, ...) and with app libraries from `home-libsonnet`; do not add
  wrapper layers. Fall back to plain objects when a library lacks
  the type. Use `_config+::` (not `_config::`) so defaults are kept.
- Customise with idiomatic Jsonnet mixins, not a values.yaml-style `_config`. `_config`
  is for a few real knobs (namespace, version, replica counts). Anything else extends the
  object itself: libraries expose hidden fields (`controller_container::`, a Deployment,
  ...) and the app adds to them, for example
  `controller_container+:: { args+: ['--feature-gates=...'] }`. Never add a config key
  that only forwards a list or object into one place (like `extraArgs`); if a library
  lacks the hidden field to mix into, add it to the library in `home-libsonnet`.
- Split an app by responsibility, one `.libsonnet` file per concern, each a plain object
  using `$._config` and hidden fields, merged with `+` in `main.libsonnet`. For
  cert-manager: `certmanager.libsonnet` (the operator and its flags), `secrets.libsonnet`
  (`ExternalSecret`s), `letsencrypt.libsonnet` (the `ClusterIssuer`).
  Every app has a `config.libsonnet` holding all of its `_config+::` defaults (never
  scattered across the concern files), merged right after the library it configures.
  Container images are not config: every app has an `images.libsonnet` overriding the
  library's `_images+::` with a `// renovate: datasource=docker depName=<image>` comment per
  image, so Renovate bumps them here (the `renovate.json` manager matches `images.libsonnet`).
  Libraries must define their images the same way, never in `_config`. The
  concern files import the libraries they need and refer to each other through `$` (for
  example the issuer reads `$.cloudflareSecret.metadata.name`). Do not put everything in
  one big `main.libsonnet`.
- Ship CRDs in the same app as the objects that use them. Flux applies CRDs and
  namespaces first, so no extra ordering is needed inside an app.
- Order between apps with one label per dependency in `spec.json`, for example
  `"labels": { "flux.bednarzak.com/depends-on.external-secrets": "true" }`. Apps
  that use `ExternalSecret` depend on `external-secrets`. The generated
  `Kustomization` waits (`wait: true`) for them.
- Namespaces Flux creates are plain `k8s-libsonnet` namespaces annotated
  `kustomize.toolkit.fluxcd.io/prune: disabled`, so removing an app never deletes
  the namespace and its volumes. Never manage `kube-system` or other pre-existing
  namespaces.
- Deploy the app itself in this order of preference: (1) an existing open source
  library; (2) if none exists, create one in `home-libsonnet` and use that. Do not
  fall back to a Helm chart.
- Secrets are never in these files. Reference them by name/key through
  `ExternalSecret` objects against the `cluster-secrets` `ClusterSecretStore`.
- Deleting an app from `apps/` removes it from the cluster once rendered, because
  the `Kustomization` is pruned. Check the CI diff comment before merging.
- Tanka's `manifest.json` (file => environment map written by `tk export`) is kept
  in each rendered `apps/<cluster>/<app>/`; Flux ignores non-YAML files.
- The PR diff comment is built by `scripts/diff-flux.sh`: grouped by app, one
  collapsed section per file.

Render and compare locally:

```sh
scripts/render-flux.sh bet1 /tmp/out   # needs jsonnet, jb, tk, yq, flux, jq and network
```

The `Lint` workflow runs `jsonnetfmt --test` on Jsonnet under `apps/` and `clusters/`; fix
with `jsonnetfmt -i <file>`.

## Argo CD and Jsonnet Patterns (legacy)

These apply to apps still under `argo/`. Do not add new apps here; add them under
`apps/` instead.

ApplicationSets generally follow this pattern:

```jsonnet
local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';

local source = helm.new('app-name', values={});

appset.new('app-name', 'namespace')
+ appset.addSource(source)
```

Use the shared helpers before adding new shapes:

- `appset.new(name, namespace)` creates the common ApplicationSet skeleton.
- `appset.addSource(source)` appends Helm or git sources.
- `appset.addIgnoreDifferences(...)` handles Argo drift exceptions.
- `helm.new(...)` defines the primary Helm source and automatically looks for
  `values.yaml`, `default.values.yaml`, and `<cluster>.values.yaml`.
- `helm.extraObjects(...)` attaches `charts/extra-objects` and automatically
  looks for `extra.values.yaml` and `<cluster>.extra.values.yaml`.
- `util.ingress(...)`, `util.env(...)`, and `util.secretEnv(...)` keep common
  Kubernetes value structures consistent.

Cluster-specific templating uses ApplicationSet Go templates such as
`{{ .cluster }}` and `{{ .domain }}`, sourced from files under
`argo/clusters/`.

## Tanka

Some apps use Grafana Tanka instead of Helm to produce Kubernetes manifests.
Tanka-based apps are identified by `jsonnetfile.json` in their directory and
may contain `spec.json`, `main.jsonnet`, and `vendor/`.

### The `spec.json` situation

`spec.json` is **gitignored** and ephemeral. It tells Tanka which Kubernetes
API server and namespace to target, but is never used for actual deployment.
It is generated on the fly from cluster metadata by both the Argo CD CMP and
the local `scripts/tk-show` helper:

1. Back up any existing `spec.json`.
2. Generate a fresh one pointing at the target apiserver/namespace.
3. Rename `main.jsonnet` to `_main.jsonnet`, create a wrapper that applies
   overrides.
4. Run `tk show`, then restore original files on cleanup.

### Local testing

Use `scripts/tk-show` to render a Tanka app locally without Argo CD:

```sh
TANKA_NAMESPACE=<ns> scripts/tk-show argo/apps/<app>
```

Environment variables control the same knobs as the CMP:
`TANKA_NAMESPACE`, `TANKA_APISERVER`, `TANKA_CLUSTER`, `TANKA_APP`,
and `TANKA_OVERRIDES` (a Jsonnet expression merged into `main.jsonnet`).

### The `tanka.libsonnet` helper

`argo/lib/tanka.libsonnet` builds the Argo CD ApplicationSet source spec
for Tanka apps. It sets the `plugin` field (instead of `helm` or `kustomize`)
and passes all Tanka environment variables as ApplicationSet Go template
expressions:

```jsonnet
local tanka = import '../lib/tanka.libsonnet';
local source = tanka.new('metrics', namespace='metrics-system',
  overrides={ _namespace:: 'metrics-system', _cluster:: '{{ .cluster }}' });
```

## Adding or Updating Apps

New apps are added under `apps/` as described in "Flux Apps". The steps below
are for apps that still live in `argo/`.

When adding an Argo app:

1. Add or update `argo/appsets/<app>.jsonnet`.
2. Put chart values in `argo/apps/<app>/values.yaml`,
   `default.values.yaml`, or `<cluster>.values.yaml` as appropriate.
3. Put raw Kubernetes extras in `argo/apps/<app>/extra.values.yaml` when the
   `extra-objects` chart is the existing fit.
4. Prefer shared Jsonnet helpers for ingress and secret env wiring.
5. Add Renovate comments for chart or release versions when matching existing
   patterns.
6. Keep secrets referenced by name/key only; store actual values through the
   encrypted secret workflow.

For local Helm charts, keep templates small and conventional. For third-party
charts, prefer values over template overlays unless the chart cannot express the
needed object.

## Validation Ideas

Pick the lightest check that matches the change:

```sh
scripts/render-flux.sh bet1 /tmp/out
jsonnet argo/appsets/<app>.jsonnet
TANKA_NAMESPACE=<ns> scripts/tk-show argo/apps/<app>
helm lint charts/<chart>
helm template <release> charts/<chart> -f charts/<chart>/values.yaml
ansible-playbook -i ansible/inventory/bet1/hosts.ini ansible/site.yml --syntax-check
```

To see what a change would actually alter, render every ApplicationSet to plain
manifests and diff against another checkout (this is what the `Manifest diff`
workflow does on PRs; Secret values are redacted):

```sh
scripts/render-apps.js render . /tmp/head
scripts/render-apps.js render ../homelab-main /tmp/base
scripts/render-apps.js diff /tmp/base /tmp/head
```

Some checks may require installed Ansible collections, cluster access, decrypted
secrets, or network access. If validation cannot run locally, say exactly what
was and was not checked.

## Style and Change Boundaries

- Favor the current layout over introducing new tooling or abstractions.
- Keep YAML and Jsonnet diffs focused; avoid reformatting unrelated manifests.
- Preserve the distinction between Ansible bootstrap concerns and application
  concerns (Flux, or Argo while apps are being migrated).
- This is a homelab: pragmatic experiments are welcome, but do not make
  irreversible live-infrastructure changes without clear user intent.
- Do not remove commented future directions unless the user asks; they may be
  breadcrumbs for experiments.
