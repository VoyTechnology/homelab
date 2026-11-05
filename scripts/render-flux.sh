#!/usr/bin/env bash
set -euo pipefail

# Render the Flux bootstrap config for a cluster into an output directory:
#   scripts/render-flux.sh bet1 ../homelab-manifests/clusters/bet1/flux-system
# gotk-components.yaml comes from the pinned flux2 CLI, the sync config from
# clusters/environments/<cluster>; libraries are shared via clusters/jsonnetfile.json.
cluster="${1:?usage: render-flux.sh <cluster> <out-dir>}"
out="${2:?usage: render-flux.sh <cluster> <out-dir>}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_dir="$root/clusters/environments/$cluster"

mkdir -p "$out"
(cd "$root/clusters" && jb install >/dev/null)

jsonnet -J "$root/clusters/vendor" -S -m "$out" "$env_dir/main.jsonnet" >/dev/null
# jsonnet -S adds a trailing newline only in some versions; normalize to one.
for f in "$out"/kustomization.yaml; do printf '%s\n' "$(cat "$f")" > "$f"; done
# jsonnet quotes every string; flux does not.
yq -i -P '.' "$out/gotk-sync.yaml"

flux install --export > "$out/gotk-components.yaml"
