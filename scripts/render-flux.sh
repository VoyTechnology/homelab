#!/usr/bin/env bash
set -euo pipefail

# Render the Flux bootstrap config for a cluster into an output directory:
#   scripts/render-flux.sh bet1 ../homelab-manifests/clusters/bet1/flux-system
# Everything, including the Flux version for gotk-components.yaml, is defined in
# clusters/environments/<cluster>; libraries are shared via clusters/jsonnetfile.json.
cluster="${1:?usage: render-flux.sh <cluster> <out-dir>}"
out="${2:?usage: render-flux.sh <cluster> <out-dir>}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_dir="$root/clusters/environments/$cluster"

mkdir -p "$out"
(cd "$root/clusters" && jb install >/dev/null)
version="$(jsonnet -J "$root/clusters/vendor" -S -e "(import '$env_dir/main.jsonnet').version")"

jsonnet -J "$root/clusters/vendor" -S -m "$out" "$env_dir/main.jsonnet" >/dev/null
# jsonnet -S adds a trailing newline only in some versions; normalize to one.
for f in "$out"/kustomization.yaml; do printf '%s\n' "$(cat "$f")" > "$f"; done
# jsonnet quotes every string; flux does not.
yq -i -P '.' "$out/gotk-sync.yaml"

flux install --export --version="$version" > "$out/gotk-components.yaml"
