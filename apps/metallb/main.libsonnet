// One file per responsibility, merged as mixins; config.libsonnet holds the knobs.
(import 'github.com/VoyTechnology/home-libsonnet/metallb/main.libsonnet')
+ (import 'config.libsonnet')
+ (import 'images.libsonnet')
+ (import 'scaling.libsonnet')
+ (import 'namespace.libsonnet')
+ (import 'pools.libsonnet')
