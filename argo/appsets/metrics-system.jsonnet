local appset = import '../lib/appset.libsonnet';
local tanka = import '../lib/tanka.libsonnet';
local helm = import '../lib/helm.libsonnet';

local namespace = 'metrics-system';

local source = tanka.new(
  'metrics',
  namespace=namespace,
  overrides={
    _namespace:: namespace,
    _cluster:: '{{ .cluster }}',
  },
);

local objectStore = helm.new(
  'seaweedfs',
  repoURL='https://seaweedfs.github.io/seaweedfs/helm',
  chart='seaweedfs',
  // renovate: datasource=helm depName=seaweedfs registryUrl=https://seaweedfs.github.io/seaweedfs/helm
  targetRevision='4.40.0',
  valuesApp='metrics',
  valuesPrefix='seaweedfs',
);

appset.new('metrics', namespace)
+ appset.addSource(source)
+ appset.addSource(objectStore)
