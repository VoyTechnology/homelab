// Home Assistant's route. Exposed through a Cloudflare Gateway (a tunnel); DNS is managed by the gateway
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
}
