#!/usr/bin/env bash
set -euo pipefail

# Markdown diff of a rendered cluster against homelab-manifests, grouped by what
# changed (Flux itself, then one section per app) with every file collapsed, small
# files first so the size budget goes to the diffs that are quick to review:
#   scripts/diff-flux.sh <base-root> <head-root> <cluster> [total-chars]
base="${1:?usage: diff-flux.sh <base-root> <head-root> <cluster> [total-chars]}"
head="${2:?}"
cluster="${3:?}"
# Total budget for diff bodies; files past it are listed without their diff (GitHub
# comments are limited to 65536 characters).
budget="${4:-50000}"
used=0

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

changed="$(while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  if ! cmp -s "$base/$f" "$head/$f" 2>/dev/null; then
    size="$(cat "$base/$f" "$head/$f" 2>/dev/null | wc -c)"
    printf '%s\t%012d\t%s\n' "$(group "$f")" "$size" "$f"
  fi
done <<<"$files" | sort -t$'\t' -k1,1 -k2,2n -k3,3 | cut -f1,3)"

echo "### Flux \`$cluster\`: diff against homelab-manifests"
if [[ -z "$changed" ]]; then
  echo
  echo "No changes."
  exit 0
fi

current=""
while IFS=$'\t' read -r g f; do
  if [[ "$g" != "$current" ]]; then
    current="$g"
    echo
    echo "#### $g"
    echo
  fi
  a="$base/$f"; b="$head/$f"
  if [[ ! -e "$a" ]]; then status="added"; a=/dev/null
  elif [[ ! -e "$b" ]]; then status="removed"; b=/dev/null
  else status="modified"; fi
  body="$(diff -u --label "base/$f" --label "head/$f" "$a" "$b" || true)"
  plus="$(grep -c '^+[^+]' <<<"$body" || true)"
  minus="$(grep -c '^-[^-]' <<<"$body" || true)"
  echo "<details><summary><code>${f##*/}</code>: $status (+$plus −$minus)</summary>"
  echo
  if (( used + ${#body} > budget )); then
    echo "Diff omitted (over the size limit), see the workflow summary."
  else
    used=$((used + ${#body}))
    echo '```diff'
    echo "$body"
    echo '```'
  fi
  echo
  echo "</details>"
done <<<"$changed"
