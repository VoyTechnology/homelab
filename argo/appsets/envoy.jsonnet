local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';

local source = helm.new(
    'envoy',
    repoURL='docker.io/envoyproxy',
    chart='gateway-helm',
    targetRevision='v1.7.0',
);

local extraObjects = helm.extraObjects('envoy', values={
    domain: '{{ .domain }}',
});

appset.new('envoy', 'envoy-gateway-system')
+ appset.addSource(source)
+ appset.addSource(extraObjects)
+ {
    spec+: {template+: {spec+: { syncPolicy+: {
        syncOptions+: [
            'ServerSideApply=true',
        ]
    }}}}
}
