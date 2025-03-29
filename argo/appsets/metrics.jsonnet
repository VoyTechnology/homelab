local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local util = import '../lib/util.libsonnet';

local mimirSource = helm.new('metrics',
  repoURL="https://grafana.github.io/helm-charts",
  chart="mimir-distributed",
  targetRevision="5.6.0",
  values={
    ingress: util.ingress('metrics', class='internal-login'),
    metaMonitoring: { serviceMonitor: {
      clusterLabel: '{{ .cluster }}',
    } },
  }
);

local extraObjects = helm.new('metrics-extra-objects',
  path='charts/extra-objects',
  values={
    cluster_name: '{{ .cluster }}',
  }
);

appset.new('metrics', 'metrics')
+ appset.addSource(mimirSource)
+ appset.addSource(extraObjects)
