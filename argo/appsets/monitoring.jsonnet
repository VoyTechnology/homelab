local appset = import '../lib/appset.libsonnet';
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

// Everything in this app -- Grafana, Alloy, kube-state-metrics,
// node-exporter, and the grafana-cloud ExternalSecret -- is now rendered
// by the Tanka source above. Nothing left templated through Helm.
appset.new('monitoring', namespace)
+ appset.addSource(source)
