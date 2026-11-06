// One file per responsibility, merged as mixins; config.libsonnet holds the knobs.
(import 'github.com/VoyTechnology/home-libsonnet/cloudflare-gateway-controller/main.libsonnet')
+ (import 'config.libsonnet')
+ (import 'images.libsonnet')
+ (import 'namespace.libsonnet')
+ (import 'secrets.libsonnet')
+ (import 'gatewayclass.libsonnet')
+ (import 'referencegrants.libsonnet')
