#!/usr/bin/env bash
set -euo pipefail

# Push the alert rules from apps/lib/monitoring/alerts.libsonnet to Grafana Cloud as Grafana-managed rules.
#   GRAFANA_SERVER=https://<stack>.grafana.net GRAFANA_TOKEN=<service account token> \
#     scripts/push-grafana-alerts.sh [bet1] [--dry-run]
# The token needs to write folders and alert rules. Each rule group is replaced as a whole; groups removed from
# the Jsonnet are not deleted in Cloud.
cluster="${1:-bet1}"
dry_run="${2:-}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

(cd "$root/apps" && jb install >/dev/null)
alerts="$(cd "$root/apps" && tk eval "environments/monitoring/$cluster" -e cloudAlerts)"

if [[ "$dry_run" == "--dry-run" ]]; then
  jq -r '.groups[] | "\(.name): \(.rules | length) rules"' <<<"$alerts"
  exit 0
fi

: "${GRAFANA_SERVER:?}" "${GRAFANA_TOKEN:?}"
api() { curl -fsS -H "Authorization: Bearer $GRAFANA_TOKEN" -H 'Content-Type: application/json' "$@"; }

# The folder may already exist (409/412).
folder_uid="$(jq -r '.folder.uid' <<<"$alerts")"
jq -c '.folder' <<<"$alerts" \
  | api -X POST "$GRAFANA_SERVER/api/folders" -d @- >/dev/null 2>&1 || true

jq -c '.groups[]' <<<"$alerts" | while read -r group; do
  name="$(jq -r '.name' <<<"$group")"
  echo "Pushing rule group $name"
  api -X PUT "$GRAFANA_SERVER/api/v1/provisioning/folder/$folder_uid/rule-groups/$name" \
    -d "$(jq -c '{title: .name, folderUid, interval, rules}' <<<"$group")" >/dev/null
done
