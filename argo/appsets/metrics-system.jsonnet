local appset = import '../lib/appset.libsonnet';
local tanka = import '../lib/tanka.libsonnet';

local source = tanka.new(
  'metrics',
  // renovate: datasource=docker depName=grafana/mimir
  targetRevision='main',
  namespace='metrics-system',
  overrides={
    _config: {
      ingester_allow_multiple_replicas_on_same_node: true,
      store_gateway_allow_multiple_replicas_on_same_node: true,
    },
  },
);

appset.new('metrics', 'metrics-system')
+ appset.addSource(source)
