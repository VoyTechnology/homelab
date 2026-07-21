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
- `argo/` contains Argo CD ApplicationSet definitions and app values.
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
- `.github/workflows/` runs Renovate and Ansible workflows.

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
- Base k3s service tasks are split into namespaces, secrets, cert-manager, dex,
  ingress, Argo CD, and extra CRDs.
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

## Argo CD and Jsonnet Patterns

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

When adding an app:

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
jsonnet argo/appsets/<app>.jsonnet
TANKA_NAMESPACE=<ns> scripts/tk-show argo/apps/<app>
helm lint charts/<chart>
helm template <release> charts/<chart> -f charts/<chart>/values.yaml
ansible-playbook -i ansible/inventory/bet1/hosts.ini ansible/site.yml --syntax-check
```

Some checks may require installed Ansible collections, cluster access, decrypted
secrets, or network access. If validation cannot run locally, say exactly what
was and was not checked.

## Style and Change Boundaries

- Favor the current layout over introducing new tooling or abstractions.
- Keep YAML and Jsonnet diffs focused; avoid reformatting unrelated manifests.
- Preserve the distinction between Ansible bootstrap concerns and Argo-managed
  application concerns.
- This is a homelab: pragmatic experiments are welcome, but do not make
  irreversible live-infrastructure changes without clear user intent.
- Do not remove commented future directions unless the user asks; they may be
  breadcrumbs for experiments.
