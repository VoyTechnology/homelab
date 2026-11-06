// One file per responsibility, merged as mixins; config.libsonnet holds the knobs.
(import 'github.com/VoyTechnology/home-libsonnet/envoy-gateway/main.libsonnet')
+ (import 'config.libsonnet')
+ (import 'images.libsonnet')
+ (import 'namespace.libsonnet')
+ (import 'controlplane.libsonnet')
+ (import 'gateways.libsonnet')
