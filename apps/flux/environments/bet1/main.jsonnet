// Tanka environment for the bet1 cluster. Cluster name and namespace are read from
// std.extVar('tanka.dev/environment') (this directory's name and spec.json).
(import 'sync.libsonnet')
+ (import 'config.libsonnet')
