# Homelab

Homelab running on k3s

---

## Tools

Necessary tools and their versions are managed using [mise], This way we only have to run one
command to install all the necessary tooling.

```sh
mise install
```

## Creating new Cluster

1. Provision individual machine with Debian
   - Ensure that the `root` user can be logged into using the SSH key
   - Change the hostname to match the naming scheme (`s{n}-{cluster}`)
   - Install, start and enable Tailscale on each node
1. Create a new folder in inventory named `{cluster}`, add the `group_vars` and
   `hosts.ini` file. Refer to each machine using the hostname
1. Run the `site.yml` on the cluster to initialize the initial state

---

## Deploying apps with Flux

Flux reconciles the `homelab-manifests` repository. This repo renders into it:
Jsonnet in `clusters/` defines Flux itself and Jsonnet in `apps/` defines apps.
The `Render Flux` workflow renders both, comments the diff against
`homelab-manifests` on pull requests, and commits the result on merge to `main`.

```text
apps/<app>/main.libsonnet                        app definition
apps/<app>/environments/<cluster>/main.jsonnet   per-cluster Tanka environment
apps/<app>/environments/<cluster>/spec.json      Tanka spec (namespace, ...)
```

To add an app:

1. Create `apps/<app>/main.libsonnet` using the generated libraries directly
   (`k8s-libsonnet` and others), plus app libraries from
   [home-libsonnet](https://github.com/VoyTechnology/home-libsonnet) where they exist.
   Look at `apps/external-secrets` for an example.
1. Add `apps/<app>/environments/<cluster>/` with a `main.jsonnet` and a `spec.json` for
   each cluster that runs it. The Flux `Kustomization` is generated for you.
1. Render locally with `scripts/render-flux.sh <cluster> /tmp/out`.
1. Open a pull request and review the rendered diff comment.

To add a cluster, create `clusters/environments/<cluster>/main.jsonnet`. Apps
that should run there get their own environment directory.

The legacy Argo CD apps under `argo/` are being moved to this layout.

---

## Running a single playbook on the cluster

This is done via Github Actions. The action will connect to the cluster with
Ephemeral Key (this will expire one day, make sure to update). Then run it by
providing the cluster name, and the playbook name to run (include the `_` in the
name, but exclude the `.yml` extension)

[mise]: https://github.com/jdx/mise
