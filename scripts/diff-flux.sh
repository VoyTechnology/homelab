#!/usr/bin/env bash
set -euo pipefail

# Markdown diff of a rendered cluster against homelab-manifests, as a summary table, then one collapsed diff per group (Flux
# itself, then each app):
#   scripts/diff-flux.sh <base-root> <head-root> <cluster> [total-chars]
base="${1:?usage: diff-flux.sh <base-root> <head-root> <cluster> [total-chars]}"
head="${2:?}"
cluster="${3:?}"
# Total budget for diff bodies; files past it are listed without their diff (GitHub
# comments are limited to 65536 characters).
budget="${4:-50000}"
used=0
# Redactions applied before diffing (see the file); the rendered files themselves are left alone.
redactions="${FLUX_REDACTIONS:-$(dirname "${BASH_SOURCE[0]}")/flux-redactions.yaml}"

paths=("clusters/$cluster/flux-system" "clusters/$cluster/apps" "apps/$cluster")

# Group heading for a repo-relative file.
group() {
  case "$1" in
    clusters/$cluster/flux-system/*) echo "Flux" ;;
    clusters/$cluster/apps/*) f="${1##*/}"; echo "${f%.yaml}" ;;
    apps/$cluster/*) f="${1#apps/$cluster/}"; echo "${f%%/*}" ;;
  esac
}

files="$(for root in "$base" "$head"; do
  for p in "${paths[@]}"; do (cd "$root" && find "$p" -type f 2>/dev/null); done
done | sort -u)"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# redact <file> <out>: copy a file with every path of the matching redactions replaced by a hash of its value.
redact() {
  cp "$1" "$2"
  local n i when p h
  n="$(yq 'length' "$redactions")"
  for ((i = 0; i < n; i++)); do
    when="$(yq ".[$i].when" "$redactions")"
    [[ "$(yq "$when" "$2")" == "true" ]] || continue
    while IFS= read -r p; do
      [[ "$(yq "[$p] | length" "$2")" != "0" ]] || continue
      h="$(yq -o=json "[$p]" "$2" | sha256sum | cut -c1-12)"
      yq -i "($p) = \"<redacted sha256-$h>\"" "$2"
    done < <(yq ".[$i].paths[]" "$redactions")
  done
}

# One combined diff per group plus added/changed/removed counts, groups sorted by name.
groups=()
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  cmp -s "$base/$f" "$head/$f" 2>/dev/null && continue
  g="$(group "$f")"
  a="$base/$f"; b="$head/$f"
  if [[ ! -e "$a" ]]; then k=added; a=/dev/null; la=/dev/null; lb="head/$f"
  elif [[ ! -e "$b" ]]; then k=removed; b=/dev/null; la="base/$f"; lb=/dev/null
  else k=changed; la="base/$f"; lb="head/$f"; fi
  [[ -e "$tmp/$g.diff" ]] || groups+=("$g")
  echo "$k" >>"$tmp/$g.kinds"
  [[ "$a" == /dev/null ]] || { redact "$a" "$tmp/a.yaml"; a="$tmp/a.yaml"; }
  [[ "$b" == /dev/null ]] || { redact "$b" "$tmp/b.yaml"; b="$tmp/b.yaml"; }
  diff -u --label "$la" --label "$lb" "$a" "$b" >>"$tmp/$g.diff" || true
done <<<"$files"

echo "### Flux \`$cluster\`: diff against homelab-manifests"
if (( ${#groups[@]} == 0 )); then
  echo
  echo "No changes."
  exit 0
fi

mapfile -t groups < <(printf '%s\n' "${groups[@]}" | sort)

echo
echo "What Flux would apply, rendered from the head commit against homelab-manifests (files added / changed / removed)."
echo
echo "| Application | Added | Changed | Removed |"
echo "|---|---|---|---|"
for g in "${groups[@]}"; do
  n() { grep -cx "$1" "$tmp/$g.kinds" || true; }
  echo "| \`$g\` | +$(n added) | ~$(n changed) | -$(n removed) |"
done
echo

for g in "${groups[@]}"; do
  size="$(wc -c <"$tmp/$g.diff")"
  if (( used + size > budget )); then
    echo "_\`$g\` and later diffs omitted: comment size limit. See the workflow summary for the full diff._"
    break
  fi
  used=$((used + size))
  echo "<details><summary><code>$g</code></summary>"
  echo
  echo '```diff'
  cat "$tmp/$g.diff"
  echo '```'
  echo
  echo "</details>"
  echo
done
