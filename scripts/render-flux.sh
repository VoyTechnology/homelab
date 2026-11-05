#!/usr/bin/env bash
set -euo pipefail

# Render everything Flux needs for a cluster into the layout of homelab-manifests:
#   scripts/render-flux.sh bet1 ../homelab-manifests
#     clusters/<cluster>/flux-system/   Flux itself, from clusters/environments/<cluster>
#     clusters/<cluster>/apps/          one Flux Kustomization per app unit
#     apps/<cluster>/<unit>/            the units' manifests
# Apps are Tanka environments: apps/*/environments/<cluster> (see apps/AGENTS.md). The Flux version for
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
# Every apps/<app>/environments/<cluster> is a Tanka environment. Each is exported to
# apps/<cluster>/<app>/ and gets a Flux Kustomization in clusters/<cluster>/apps/.
# This render owns these two directories entirely.
rm -rf "$out/clusters/$cluster/apps" "$out/apps/$cluster"
for env in "$root"/apps/*/environments/"$cluster"; do
  [[ -d "$env" ]] || continue
  app="$(basename "$(dirname "$(dirname "$env")")")"
  app_out="$out/apps/$cluster/$app"
  mkdir -p "$app_out" "$out/clusters/$cluster/apps"

  (cd "$root/apps" && tk export "$app_out" "${env#"$root/apps/"}" \
    --format '{{.kind | lower}}-{{.metadata.name}}' --extension yaml >/dev/null)
  rm -f "$app_out/manifest.json"
  for f in "$app_out"/*.yaml; do
    # Tanka-only metadata has no place in the cluster.
    yq -i -P 'del(.metadata.annotations."tanka.dev/namespaced") | del(.metadata.annotations | select(length == 0))' "$f"
  done

  # Optional ordering: spec.json metadata.labels.depends-on = "app-a,app-b".
  depends="$(jq -r '.metadata.labels["depends-on"] // empty' "$env/spec.json")"
  flux create kustomization "$app" --namespace=flux-system \
    --source=GitRepository/flux-system --path="./apps/$cluster/$app" \
    --prune=true --wait=true --interval=10m ${depends:+--depends-on="$depends"} \
    --export | sed '1{/^---$/d;}' | yq -P '.' > "$out/clusters/$cluster/apps/$app.yaml"
done
