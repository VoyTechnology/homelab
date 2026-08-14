// grafana.addMixinDashboards() (see the vendored grafana/dashboards.libsonnet)
// expects an object keyed by mixin name, each value being that mixin's own
// jsonnet-libs mixin object — not a single object with all mixins merged
// together. Merging them flatly (the previous shape here) meant
// addMixinDashboards's `mixins[name].grafanaDashboards` lookup never matched
// anything, so no dashboard ever made it into a ConfigMap.
{
  argocd: import 'github.com/grafana/jsonnet-libs/argocd-mixin/mixin.libsonnet',
  envoy: import 'github.com/grafana/jsonnet-libs/envoy-mixin/mixin.libsonnet',
}
