# Apps (Flux)

Read the "Flux Apps" section in the root `AGENTS.md` first. Short version:

- Every app is a Tanka application: a `main.libsonnet` that merges one `<concern>.libsonnet`
  mixin file per responsibility (`certmanager`, `secrets`, `letsencrypt`, ...) plus
  `environments/<cluster>/{main.jsonnet,spec.json}`. `spec.json` is committed here.
- Use the generated libsonnet libraries and `home-libsonnet` directly, no wrapper
  helpers. Do not write Flux `Kustomization`s; `scripts/render-flux.sh` generates one
  per environment. Order apps with `flux.bednarzak.com/depends-on.<app>: "true"` labels in `spec.json`.
- Render with `scripts/render-flux.sh <cluster> /tmp/out` (or `tk show` in this
  directory) and inspect the output before proposing changes. `vendor/` is
  gitignored; `jb install` fills it.
- Never put secret values here; use `ExternalSecret` against `cluster-secrets`.
- Do not manage `kube-system` or other pre-existing namespaces.
- Customise by mixing into the library's hidden fields (`controller_container+:: { args+: [...] }`),
  not by growing `_config` into a values dump; see the root `AGENTS.md`.
