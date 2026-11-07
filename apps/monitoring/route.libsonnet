// Grafana is on the exposed gateway. No generated library for the Gateway API, so a plain object.
{
  route: {
    apiVersion: 'gateway.networking.k8s.io/v1',
    kind: 'HTTPRoute',
    metadata: { name: 'grafana', namespace: $._config.namespace },
    spec: {
      parentRefs: [{ kind: 'Gateway', namespace: $._config.gateway.namespace, name: 'exposed' }],
      hostnames: ['grafana.%s' % $._config.domain],
      rules: [{ backendRefs: [{ name: 'grafana', port: 80 }] }],
    },
  },
}
