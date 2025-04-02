local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local util = import '../lib/util.libsonnet';

local lokiSource = helm.new('logs',
  repoURL="https://grafana.github.io/helm-charts",
  chart="loki",
  targetRevision="6.29.0",
  values={
    gateway: { ingress: util.ingress('logs', class='internal-login') {
      hosts: [{
        host: 'logs.{{ .domain }}',
        paths: [{ path: '/', pathType: 'Prefix' }],
      }],
    } },
    metaMonitoring: { serviceMonitor: {
      clusterLabel: '{{ .cluster }}',
    } },
  }
);

local extraObjects = helm.extraObjects('logs', values={
  cluster_name: '{{ .cluster }}',
  domain: '{{ .domain }}',
});

appset.new('logs', 'logs')
+ appset.addSource(lokiSource)
+ appset.addSource(extraObjects)
