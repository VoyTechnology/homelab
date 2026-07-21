local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local tanka = import '../lib/tanka.libsonnet';
local util = import '../lib/util.libsonnet';

local namespace = 'monitoring';

local source = tanka.new(
  'grafana',
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

local alloySource = helm.new('monitoring', values={
  cluster_name: '{{ .cluster }}',
  alloy: {
    ingress: util.ingress('alloy', class='internal-login'),
    alloy: { extraEnv: [
      util.env('CLUSTER_NAME', '{{ .cluster }}'),
      util.secretEnv('GRAFANA_USER', 'grafana-cloud', 'user'),
      util.secretEnv('LOKI_URL', 'grafana-cloud', 'logs-url'),
      util.secretEnv('LOKI_USER', 'grafana-cloud', 'loki-user'),
      util.secretEnv('PROMETHEUS_URL', 'grafana-cloud', 'metrics-url'),
      util.secretEnv('REMOTE_CONFIG_URL', 'grafana-cloud', 'remote-config-url'),
      util.secretEnv('TOKEN', 'grafana-cloud', 'token'),
    ] },
  },
});
local extraObjects = helm.extraObjects('monitoring');

appset.new('monitoring', namespace)
+ appset.addSource(source)
+ appset.addSource(alloySource)
+ appset.addSource(extraObjects)
