(import 'homeassistant/main.libsonnet')
+ {
  // Home Assistant is exposed through the shared Cloudflare Gateway.
  route+: { spec+: { parentRefs: [{ name: 'external-cloudflare', namespace: 'gateway-system' }] } },
}
