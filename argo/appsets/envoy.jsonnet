local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';

local source = helm.new(
    'envoy',
    repoURL='docker.io/envoyproxy',
    chart='gateway-helm',
    targetRevision='v1.7.0',
);

appset.new('envoy', 'envoy-gateway-system')
+ appset.addSource(source)
+ {
    spec+: {template+: {spec+: { syncPolicy+: {
        syncOptions+: [
            'ServerSideApply=true',
        ]
    }}}}
}
