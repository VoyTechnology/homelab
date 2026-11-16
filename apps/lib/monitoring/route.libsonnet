// Grafana is served through the Cloudflare tunnel gateway. No generated library for the Gateway API, so a plain object.
{
  route: {
    apiVersion: 'gateway.networking.k8s.io/v1',
    kind: 'HTTPRoute',
    metadata: { name: 'grafana', namespace: $._config.namespace },
    spec: {
      parentRefs: [{ kind: 'Gateway', namespace: $._config.gateway.namespace, name: $._config.gateway.name }],
      hostnames: [$._config.grafanaHost],
      rules: [{ backendRefs: [{ name: 'grafana', port: 80 }] }],
    },
  },
}
