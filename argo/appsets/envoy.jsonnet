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
    externalDnsTarget: '{{ .metadata.externalDnsTarget }}',
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
+ {
    // Deleting the appset must leave Envoy Gateway and the gateways running (they move to Flux).
    spec+: { syncPolicy+: { preserveResourcesOnDeletion: true } },
}
