// Exposed through a Cloudflare Gateway (a tunnel); DNS is managed by the gateway controller. The
// environment adds the `parentRefs` of the Gateway to attach to.
// No generated library for the Gateway API, so a plain object.
{
  route: {
    apiVersion: 'gateway.networking.k8s.io/v1',
    kind: 'HTTPRoute',
    metadata: { name: 'pocketid', namespace: $._config.namespace },
    spec: {
      hostnames: [$._config.host],
      // The operator names the Service after the PocketIDInstance.
      rules: [{ backendRefs: [{ name: $._config.instanceName, port: 1411 }] }],
    },
  },
}
