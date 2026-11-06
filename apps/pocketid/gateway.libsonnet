// Exposed through a Cloudflare tunnel; DNS is managed by the gateway controller.
// No generated library for the Gateway API, so plain objects. The controller rejects a listener
// hostname; the route's hostnames select the host instead.
{
  gateway: {
    apiVersion: 'gateway.networking.k8s.io/v1',
    kind: 'Gateway',
    metadata: { name: 'pocketid', namespace: $._config.namespace },
    spec: {
      gatewayClassName: 'external-cloudflare',
      listeners: [{ name: 'https', protocol: 'HTTPS', port: 443 }],
    },
  },

  route: {
    apiVersion: 'gateway.networking.k8s.io/v1',
    kind: 'HTTPRoute',
    metadata: { name: 'pocketid', namespace: $._config.namespace },
    spec: {
      parentRefs: [{ name: $.gateway.metadata.name }],
      hostnames: [$._config.host],
      // The operator names the Service after the PocketIDInstance.
      rules: [{ backendRefs: [{ name: $._config.instanceName, port: 1411 }] }],
    },
  },
}
