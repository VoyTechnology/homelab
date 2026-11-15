// The map is exposed through a Cloudflare Gateway; the environment adds the `parentRefs`.
{
  route: {
    apiVersion: 'gateway.networking.k8s.io/v1',
    kind: 'HTTPRoute',
    metadata: { name: 'skynet-map', namespace: $._config.namespace },
    spec: {
      hostnames: [$._config.mapHost],
      rules: [{ backendRefs: [{ name: $._config.name + '-map', port: $.ports.map.port }] }],
    },
  },
}
