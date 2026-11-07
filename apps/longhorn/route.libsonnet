// The UI is served from the internal gateway (LAN only), behind Pocket ID (see auth.libsonnet).
// No generated library for the Gateway API, so a plain object.
{
  route: {
    apiVersion: 'gateway.networking.k8s.io/v1',
    kind: 'HTTPRoute',
    metadata: { name: 'longhorn', namespace: $._config.namespace },
    spec: {
      parentRefs: [{ name: $._config.gateway.name, namespace: $._config.gateway.namespace }],
      hostnames: [$._config.host],
      rules: [{ backendRefs: [{ name: 'longhorn-frontend', port: 80 }] }],
    },
  },
}
