// Gateways of this class get their own Cloudflare tunnel; routes attach to them as usual.
{
  // No generated library for the Gateway API, so a plain object.
  gatewayClass: {
    apiVersion: 'gateway.networking.k8s.io/v1',
    kind: 'GatewayClass',
    // Cluster-scoped, so keep Tanka from adding the environment's namespace.
    metadata: { name: 'external-cloudflare', annotations: { 'tanka.dev/namespaced': 'false' } },
    spec: {
      controllerName: 'cloudflare-gateway-controller.io/controller',
      parametersRef: {
        group: '',
        kind: 'Secret',
        name: $.cloudflareSecret.spec.target.name,
        namespace: $._config.namespace,
      },
    },
  },
}
