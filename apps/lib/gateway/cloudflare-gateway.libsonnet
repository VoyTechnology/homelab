// One Gateway (so one tunnel) shared by every app. It sits next to the credentials, so no
// ReferenceGrant is needed; apps only add an HTTPRoute with hostnames, attaching from any namespace.
// No generated library for the Gateway API, so plain objects.
{
  gateway: {
    apiVersion: 'gateway.networking.k8s.io/v1',
    kind: 'Gateway',
    metadata: { name: $.gatewayClass.metadata.name, namespace: $._config.namespace },
    spec: {
      gatewayClassName: $.gatewayClass.metadata.name,
      infrastructure: {
        parametersRef: { group: 'cloudflare-gateway-controller.io', kind: 'CloudflareGatewayParameters', name: $.gatewayParameters.metadata.name },
      },
      listeners: [{
        name: 'https',
        protocol: 'HTTPS',
        port: 443,
        allowedRoutes: { namespaces: { from: 'All' } },
      }],
    },
  },
  // Places the tunnel connector (the controller creates one `primary` Deployment by default). Pinning it to
  // the node of its backends keeps their source address a pod address instead of a node's Tailscale one.
  gatewayParameters: {
    apiVersion: 'cloudflare-gateway-controller.io/v1',
    kind: 'CloudflareGatewayParameters',
    metadata: { name: 'external-cloudflare', namespace: $._config.namespace },
    spec: {
      tunnel: {
        replicas: [{ name: 'primary' } + (if $._config.tunnelNode != '' then { nodeSelector: { 'kubernetes.io/hostname': $._config.tunnelNode } } else {})],
      },
    },
  },
}
