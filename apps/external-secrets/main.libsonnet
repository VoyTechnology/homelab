// The operator's own defaults first, then this homelab's config on top.
(import 'operator.libsonnet')
+ (import 'config.libsonnet')
+ (import 'images.libsonnet')
+ (import 'scaling.libsonnet')
+ (import 'clustersecretstore.libsonnet')
