// One file per responsibility, merged as mixins; config.libsonnet holds the knobs.
(import 'external-dns/main.libsonnet')
+ (import 'config.libsonnet')
+ (import 'images.libsonnet')
+ (import 'cloudflare.libsonnet')
