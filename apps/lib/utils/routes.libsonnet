// No generated library for the Gateway API, so the HTTPRoute is a plain object.
{
  // The Gateways in `gateway-system`: LAN only with a wildcard certificate, and the Cloudflare tunnel
  // (DNS is managed by the gateway controller).
  gateways:: {
    internal: { name: 'internal', namespace: 'gateway-system' },
    external: { name: 'external-cloudflare', namespace: 'gateway-system' },
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
