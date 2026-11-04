# Tanka Experimental Directory

Native Tanka layout: one committed environment per cluster in
`environments/<cluster>/` (namespace in `spec.json`), shared code in `lib/`.
Render with `scripts/tk-show apps/x-tanka` (set `TANKA_CLUSTER` for another cluster).
Rendered manifests are published to the homelab-manifests repo (see AGENTS.md).
