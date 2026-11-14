// One file per responsibility, merged as mixins; config.libsonnet holds the knobs.
(import 'certmanager.libsonnet')
+ (import 'config.libsonnet')
+ (import 'images.libsonnet')
+ (import 'scaling.libsonnet')
+ (import 'secrets.libsonnet')
+ (import 'letsencrypt.libsonnet')
