local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.35/main.libsonnet';
local ingress = k.networking.v1.ingress;

{
  ingress:
    ingress.new('pocketid')
    + ingress.metadata.withNamespace($._config.namespace)
    // DNS is managed by the Cloudflare tunnel, not external-dns.
    + ingress.metadata.withAnnotations({ 'dns.kubernetes.io/exclude': 'true' })
    + ingress.spec.withIngressClassName('external')
    + ingress.spec.withRules([{
      host: $._config.host,
      http: { paths: [{
        path: '/',
        pathType: 'Prefix',
        // The operator names the Service after the PocketIDInstance.
        backend: { service: { name: $._config.instanceName, port: { number: 1411 } } },
      }] },
    }]),
}
