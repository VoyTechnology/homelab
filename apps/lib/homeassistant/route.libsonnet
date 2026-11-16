// Both routes attach to the internal gateway (LAN only, wildcard certificate). The environment moves Home
// Assistant to the external Cloudflare gateway (a tunnel, DNS managed by the gateway controller) with
// `route+: { spec+: { parentRefs: [...] } }`. No generated library for the Gateway API, so plain objects.
{
  local internal = [{ name: 'internal', namespace: 'gateway-system' }],

  route: {
    apiVersion: 'gateway.networking.k8s.io/v1',
    kind: 'HTTPRoute',
    metadata: { name: 'homeassistant', namespace: $._config.namespace },
    spec: {
      parentRefs: internal,
      hostnames: [$._config.domain],
      rules: [{ backendRefs: [{
        name: $.homeassistant.haService.metadata.name,
        port: $.homeassistant._config.port,
      }] }],
    },
  },

  matterhubRoute: {
    apiVersion: 'gateway.networking.k8s.io/v1',
    kind: 'HTTPRoute',
    metadata: { name: $.matterhub.matterhubService.metadata.name, namespace: $._config.namespace },
    spec: {
      parentRefs: internal,
      hostnames: [$._config.matterHost],
      rules: [{ backendRefs: [{
        name: $.matterhub.matterhubService.metadata.name,
        port: $.matterhub._config.port,
      }] }],
    },
  },
}
