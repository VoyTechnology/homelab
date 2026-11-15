(import '../../main.libsonnet')
+ {
  // Attach to the shared Cloudflare Gateway.
  route+: { spec+: { parentRefs: [{ name: 'external-cloudflare', namespace: 'gateway-system' }] } },
}
