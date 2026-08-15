// Shared Tanka override defaults for the whole monitoring app (Grafana,
// Alloy, kube-state-metrics). Kept as visible-looking hidden fields (`::`)
// so scripts/tk-show and the Argo CD CMP can merge TANKA_OVERRIDES
// (argo/appsets/monitoring.jsonnet) on top by field name -- see
// argo/lib/tanka.libsonnet for how `import(main) + overrides` works.
{
  namespace:: 'monitoring',
  cluster:: 'unknown',
  domain:: 'REPLACE_ME',
  metricsNamespace:: 'metrics-system',
}
