local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local util = import '../lib/util.libsonnet';

local source = helm.new('monitoring', values={
  cluster_name: '{{ .cluster }}',
  domain: '{{ .domain }}',
  alloy: {
    ingress: util.ingress('alloy', class='internal-login'),
    alloy: { extraEnv: [
      util.env('CLUSTER_NAME', '{{ .cluster }}'),
      util.secretEnv('TOKEN', 'grafana-cloud', 'token'),
      util.secretEnv('REMOTE_CONFIG_URL', 'grafana-cloud', 'remote-config-url'),
      util.secretEnv('METRICS_URL', 'grafana-cloud', 'metrics-url'),
      util.secretEnv('LOGS_URL', 'grafana-cloud', 'logs-url'),
    ] },
  },
});
local extraObjects = helm.extraObjects('monitoring');

local ignoreDifferences = [
  { group: '*', kind: 'Secret', name: 'monitoring-grafana', jsonPointers: ['/data/admin-password'] },
];

appset.new('monitoring', 'monitoring')
+ appset.addSource(source)
+ appset.addSource(extraObjects)
+ appset.addIgnoreDifferences(ignoreDifferences)
