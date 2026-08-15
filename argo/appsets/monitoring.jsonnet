local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local tanka = import '../lib/tanka.libsonnet';

local namespace = 'monitoring';

local source = tanka.new(
  'monitoring',
  namespace=namespace,
  overrides={
    namespace: namespace,
    cluster: '{{ .cluster }}',
    domain: '{{ .domain }}',
    metricsNamespace: 'metrics-system',
  },
);

local ignoreDifferences = [
  { group: '*', kind: 'Secret', name: 'grafana', jsonPointers: ['/data/admin-password'] },
];

// Alloy and kube-state-metrics are rendered by the Tanka source above
// (alloy.libsonnet, kube-state-metrics.libsonnet). This Helm source is left
// only for prometheus-node-exporter, still a subchart of argo/apps/monitoring
// (see Chart.yaml) since it has to run as a DaemonSet, which doesn't fit the
// hand-rolled jsonnet pattern as cleanly as the chart's own templates.
local nodeExporterSource = helm.new('monitoring');
local extraObjects = helm.extraObjects('monitoring');

appset.new('monitoring', namespace)
+ appset.addSource(source)
+ appset.addSource(nodeExporterSource)
+ appset.addSource(extraObjects)
