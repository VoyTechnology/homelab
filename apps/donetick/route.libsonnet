// Exposed through a Cloudflare Gateway (a tunnel); DNS is managed by the gateway controller. The
// environment adds the `parentRefs` of the Gateway to attach to.
// No generated library for the Gateway API, so a plain object.
{
  route: {
    apiVersion: 'gateway.networking.k8s.io/v1',
    kind: 'HTTPRoute',
    metadata: { name: 'donetick', namespace: $._config.namespace },
    spec: {
      hostnames: [$._config.host],
      rules: [{ backendRefs: [{ name: $.donetickService.metadata.name, port: $.port }] }],
    },
  },
}
