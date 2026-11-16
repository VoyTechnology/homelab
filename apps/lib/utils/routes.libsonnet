// No generated library for the Gateway API, so the HTTPRoute is a plain object.
{
  // The Gateways in `gateway-system`: `internal` (Envoy, LAN only), `exposed` (Envoy, port-forwarded
  // from the router) and `cloudflare` (the Cloudflare tunnel, DNS managed by the gateway controller).
  gateways:: {
    internal: { name: 'internal', namespace: 'gateway-system' },
    exposed: { name: 'exposed', namespace: 'gateway-system' },
    cloudflare: { name: 'external-cloudflare', namespace: 'gateway-system' },
  },

  // An HTTPRoute sending `host` to port `port` of the Service `service`, attached to `gateway` (one of
  // `gateways`). The namespace comes from the Tanka environment.
  httpRoute(name, host, service, port, gateway)::
    {
      apiVersion: 'gateway.networking.k8s.io/v1',
      kind: 'HTTPRoute',
      metadata: { name: name },
      spec: {
        parentRefs: [gateway],
        hostnames: [host],
        rules: [{ backendRefs: [{ name: service, port: port }] }],
      },
    },
}
