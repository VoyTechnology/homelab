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

// Alloy, kube-state-metrics, and node-exporter are all rendered by the
// Tanka source above (alloy.libsonnet, kube-state-metrics.libsonnet,
// node-exporter.libsonnet) -- nothing in this app is templated through
// Helm anymore except the shared extra-objects chart below.
local extraObjects = helm.extraObjects('monitoring');

appset.new('monitoring', namespace)
+ appset.addSource(source)
+ appset.addSource(extraObjects)
