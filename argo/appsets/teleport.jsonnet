local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local util = import '../lib/util.libsonnet';

local cluster = helm.new('teleport-cluster',
    repoURL='https://charts.releases.teleport.dev',
    chart='teleport-cluster',
    targetRevision='18.4.0',
    values={
        clusterName: 'teleport.{{ .domain }}',
        service: { type: 'ClusterIP'}
    },
);

appset.new('teleport', 'teleport-system')
+ appset.addSource(cluster)
