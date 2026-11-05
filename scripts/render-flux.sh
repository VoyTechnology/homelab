#!/usr/bin/env bash
set -euo pipefail

# Render everything Flux needs for a cluster into the layout of homelab-manifests:
#   scripts/render-flux.sh bet1 ../homelab-manifests
#     clusters/<cluster>/flux-system/   Flux itself, from clusters/environments/<cluster>
#     clusters/<cluster>/apps/          one Flux Kustomization per app unit
#     apps/<cluster>/<unit>/            the units' manifests
# Apps come from apps/*/environments/<cluster>/main.jsonnet, which evaluate to
# a map of repo-relative path => object. The Flux version for
# gotk-components.yaml is defined in the cluster environment, not by the CLI.
cluster="${1:?usage: render-flux.sh <cluster> <out-root>}"
out="${2:?usage: render-flux.sh <cluster> <out-root>}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_dir="$root/clusters/environments/$cluster"
flux_out="$out/clusters/$cluster/flux-system"

(cd "$root/clusters" && jb install >/dev/null)
(cd "$root/apps" && jb install >/dev/null)

# --- Flux itself ---
mkdir -p "$flux_out"
version="$(jsonnet -J "$root/clusters/vendor" -S -e "(import '$env_dir/main.jsonnet').version")"
jsonnet -J "$root/clusters/vendor" -S -m "$flux_out" "$env_dir/main.jsonnet" >/dev/null
# jsonnet -S adds a trailing newline only in some versions; normalize to one.
printf '%s\n' "$(cat "$flux_out/kustomization.yaml")" > "$flux_out/kustomization.yaml"
# jsonnet quotes every string; flux does not.
yq -i -P '.' "$flux_out/gotk-sync.yaml"
flux install --export --version="$version" > "$flux_out/gotk-components.yaml"

# --- Apps ---
# This render owns these two directories entirely.
rm -rf "$out/clusters/$cluster/apps" "$out/apps/$cluster"
for main in "$root"/apps/*/environments/"$cluster"/main.jsonnet; do
  [[ -e "$main" ]] || continue
  json="$(jsonnet -J "$root/apps/vendor" "$main")"
  # Each value is an object; write it as YAML at its repo-relative path.
  jq -r 'keys[]' <<<"$json" | while IFS= read -r path; do
    mkdir -p "$out/$(dirname "$path")"
    jq -c --arg p "$path" '.[$p]' <<<"$json" | yq -P -p json -o yaml \
      'del(.metadata.annotations."tanka.dev/namespaced") | del(.metadata.annotations | select(length == 0))' > "$out/$path"
  done
done
