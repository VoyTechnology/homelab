// One Gateway (so one tunnel) shared by every app. It sits next to the credentials, so no
// ReferenceGrant is needed; apps only add an HTTPRoute with hostnames, attaching from any namespace.
// No generated library for the Gateway API, so plain objects.
{
  gateway: {
    apiVersion: 'gateway.networking.k8s.io/v1',
    kind: 'Gateway',
    metadata: { name: $._config.gatewayName, namespace: $._config.namespace },
    spec: {
      gatewayClassName: $.gatewayClass.metadata.name,
      listeners: [{
        name: 'https',
        protocol: 'HTTPS',
        port: 443,
        allowedRoutes: { namespaces: { from: 'All' } },
      }],
    },
  },
}
