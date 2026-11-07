// The whole gateway stack in one namespace: Gateway API CRDs, Envoy Gateway (internal and exposed
// gateways) and the Cloudflare tunnel gateway. One file per responsibility, merged as mixins;
// config.libsonnet holds the knobs.
(import 'github.com/VoyTechnology/home-libsonnet/gateway-api/main.libsonnet')
+ (import 'github.com/VoyTechnology/home-libsonnet/envoy-gateway/main.libsonnet')
+ (import 'github.com/VoyTechnology/home-libsonnet/cloudflare-gateway-controller/main.libsonnet')
+ (import 'config.libsonnet')
+ (import 'images.libsonnet')
// The libraries share one `_images` and use generic keys, so point them at the descriptive ones.
+ {
  _images+:: {
    gateway: $._images.envoyGateway,
    ratelimit: $._images.envoyRatelimit,
    controller: $._images.cloudflareGateway,
  },
}
+ (import 'namespace.libsonnet')
+ (import 'secrets.libsonnet')
+ (import 'controlplane.libsonnet')
+ (import 'gateways.libsonnet')
+ (import 'cloudflare-gatewayclass.libsonnet')
+ (import 'cloudflare-gateway.libsonnet')
