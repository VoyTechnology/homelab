// Exposed through the shared Cloudflare Gateway (a tunnel); DNS is managed by the gateway controller.
// No generated library for the Gateway API, so a plain object.
{
  route: {
    apiVersion: 'gateway.networking.k8s.io/v1',
    kind: 'HTTPRoute',
    metadata: { name: 'pocketid', namespace: $._config.namespace },
    spec: {
      parentRefs: [{ name: $._config.gateway.name, namespace: $._config.gateway.namespace }],
      hostnames: [$._config.host],
      // The operator names the Service after the PocketIDInstance.
      rules: [{ backendRefs: [{ name: $._config.instanceName, port: 1411 }] }],
    },
  },
}
