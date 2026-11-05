# Apps (Flux)

Read the "Flux Apps" section in the root `AGENTS.md` first. Short version:

- One directory per app: `main.libsonnet` plus `environments/<cluster>/main.jsonnet`.
- Use `lib/flux.libsonnet` helpers; split apps into `unit`s with `dependsOn` when
  CRDs must exist first.
- Render with `scripts/render-flux.sh <cluster> /tmp/out` and inspect the output
  before proposing changes. `vendor/` is gitignored; `jb install` fills it.
- Never put secret values here; use `ExternalSecret` against `cluster-secrets`.
- Do not manage `kube-system` or other pre-existing namespaces with
  `flux.namespace`.
