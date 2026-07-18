local appset = import '../lib/appset.libsonnet';
local tanka = import '../lib/tanka.libsonnet';
local helm = import '../lib/helm.libsonnet';

local namespace = 'metrics-system';

local source = tanka.new(
  'mimir',
  // renovate: datasource=docker depName=grafana/mimir
  targetRevision='main',
  namespace=namespace,
  overrides={
    namespace: namespace,
    cluster: '{{ .cluster }}',
    memberlist_zone_aware_routing_enabled: false,
  },
);

local objectStore = helm.new(
  'seaweedfs',
  repoURL='https://seaweedfs.github.io/seaweedfs',
  chart='seaweedfs',
  // renovate: datasource=helm depName=seaweedfs registryUrl=https://seaweedfs.github.io/seaweedfs
  targetRevision='4.29.0',
  valuesApp='metrics',
  valuesPrefix='seaweedfs.',
);

appset.new('metrics', namespace)
+ appset.addSource(source)
+ appset.addSource(objectStore)
