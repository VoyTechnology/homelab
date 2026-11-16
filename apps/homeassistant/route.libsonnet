// Home Assistant's route, and Matter Hub's. Exposed through a Cloudflare Gateway (a tunnel); DNS is managed by the gateway
// controller. The environment adds the `parentRefs` of the Gateway to attach to.
// No generated library for the Gateway API, so a plain object.
{
  route: {
    apiVersion: 'gateway.networking.k8s.io/v1',
    kind: 'HTTPRoute',
    metadata: { name: 'homeassistant', namespace: $._config.namespace },
    spec: {
      hostnames: [$._config.domain],
      rules: [{ backendRefs: [{
        name: $.homeassistant.haService.metadata.name,
        port: $.homeassistant._config.port,
      }] }],
    },
  },
  // Matter Hub's web UI is only for the local network: the internal gateway, whose wildcard certificate
  // covers the host.
  matterhubRoute: {
    apiVersion: 'gateway.networking.k8s.io/v1',
    kind: 'HTTPRoute',
    metadata: { name: $.matterhub.matterhubService.metadata.name, namespace: $._config.namespace },
    spec: {
      parentRefs: [{ name: 'internal', namespace: 'gateway-system' }],
      hostnames: [$._config.matterHost],
      rules: [{ backendRefs: [{
        name: $.matterhub.matterhubService.metadata.name,
        port: $.matterhub._config.port,
      }] }],
    },
  },
}
