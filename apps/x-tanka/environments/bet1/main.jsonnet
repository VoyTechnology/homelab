// Tanka environment for the bet1 cluster. The cluster name comes from this
// directory's name and the namespace from spec.json, both read by the app via
// std.extVar('tanka.dev/environment').
(import 'grafana.libsonnet')
+ (import 'config.libsonnet')
+ {
  _config+:: {
    port: 3001,
  },
}
