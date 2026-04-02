local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';

local source = helm.new('metrics',
    repoURL='https://grafana.github.io/helm-charts',
    chart='mimir-distributed',
    // renovate: datasource=helm depName=mimir-distributed registryUrl=https://grafana.github.io/helm-charts
    targetRevision='6.0.6',
);

appset.new('metrics', 'metrics-system')
+ appset.addSource(source)
