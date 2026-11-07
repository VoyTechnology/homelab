// One file per responsibility, merged as mixins; config.libsonnet holds the knobs.
(import 'operator.libsonnet')
+ (import 'config.libsonnet')
+ (import 'images.libsonnet')
+ (import 'secrets.libsonnet')
+ (import 'instance.libsonnet')
+ (import 'groups.libsonnet')
+ (import 'route.libsonnet')
+ (import 'grants.libsonnet')
