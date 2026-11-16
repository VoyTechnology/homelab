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
- `scripts/render-flux.sh` renders Flux and all apps for a cluster into the
  layout of the `homelab-manifests` repository.
- `.github/workflows/` runs Renovate, Ansible, and Flux render workflows.

The current cluster represented in the repo is `bet1`, with Ansible inventory in
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
  ingress, and extra CRDs.
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

Flux is the deployment system.
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
      spec.json             Tanka Environment (committed)
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
  Every app also has a `scaling.libsonnet` for replica counts and CPU/memory requests and limits
  (including the scaling-related `_config+::` keys), merged after `images.libsonnet`; an app with nothing
  tuned keeps an empty one. Container images are not config: every app has an `images.libsonnet` overriding the
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
  The comment is public, so `scripts/flux-redactions.yaml` lists yq paths (per document
  selector) replaced by a hash before diffing, e.g. Secret values and the private `ha-data`
  ConfigMaps and their mounts. Add an entry for anything else that must not be posted.

Render and compare locally:

```sh
scripts/render-flux.sh bet1 /tmp/out   # needs jsonnet, jb, tk, yq, flux, jq and network
```

The `Lint` workflow runs `jsonnetfmt --test` on Jsonnet under `apps/` and `clusters/`; fix
with `jsonnetfmt -i <file>`.

## Validation Ideas

Pick the lightest check that matches the change:

```sh
scripts/render-flux.sh bet1 /tmp/out
ansible-playbook -i ansible/inventory/bet1/hosts.ini ansible/site.yml --syntax-check
```

Some checks may require installed Ansible collections, cluster access, decrypted
secrets, or network access. If validation cannot run locally, say exactly what
was and was not checked.

## Style and Change Boundaries

- Favor the current layout over introducing new tooling or abstractions.
- Keep YAML and Jsonnet diffs focused; avoid reformatting unrelated manifests.
- Preserve the distinction between Ansible bootstrap concerns and application
  concerns (Flux).
- This is a homelab: pragmatic experiments are welcome, but do not make
  irreversible live-infrastructure changes without clear user intent.
- Do not remove commented future directions unless the user asks; they may be
  breadcrumbs for experiments.
