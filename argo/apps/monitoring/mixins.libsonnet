// grafana.addMixinDashboards() (see the vendored grafana/dashboards.libsonnet)
// expects an object keyed by mixin name, each value being that mixin's own
// jsonnet-libs mixin object — not a single object with all mixins merged
// together. Merging them flatly (the previous shape here) meant
// addMixinDashboards's `mixins[name].grafanaDashboards` lookup never matched
// anything, so no dashboard ever made it into a ConfigMap.
local envoyMixin = import 'github.com/grafana/jsonnet-libs/envoy-mixin/mixin.libsonnet';

// envoy-mixin's dashboards.libsonnet hand-writes the "job" and "instance"
// template variables with current='' (a literal empty string), unlike
// envoy_cluster/envoy_listener_filter in the same file which correctly
// default to "All" ($__all). Grafana takes '' at face value -- every panel
// filtering on job=~"$job"/instance=~"$instance" resolves to matching only
// an empty label value, so every Envoy panel comes back empty until a user
// manually reselects "All" in the UI once. Patch the default to match the
// other variables (both are includeAll=true with allValues='.+' already).
local fixEmptyVarDefault(dashboard) =
  dashboard {
    templating+: {
      list: [
        if (v.name == 'job' || v.name == 'instance') && v.current.value == ''
        then v { current: { selected: true, text: 'All', value: '$__all' } }
        else v
        for v in dashboard.templating.list
      ],
    },
  };

{
  argocd: import 'github.com/grafana/jsonnet-libs/argocd-mixin/mixin.libsonnet',
  envoy: envoyMixin {
    grafanaDashboards+:: {
      [name]: fixEmptyVarDefault(envoyMixin.grafanaDashboards[name])
      for name in std.objectFields(envoyMixin.grafanaDashboards)
    },
  },
  mimir: (import 'github.com/grafana/mimir/operations/mimir-mixin/mixin.libsonnet') + {
    _config+:: {
      // Alloy converts classic histograms to native histograms with
      // custom buckets (NHCB) at scrape time (see
      // convert_classic_histograms_to_nhcb in alloy-config.alloy), so
      // default the dashboards' latency panels to the native query path
      // rather than classic buckets. Historical data recorded before
      // that change stays classic-only and won't show under this mode --
      // acceptable here since this homelab doesn't need it preserved.
      dashboards_default_latency_mode: 'native',
    },
  },
}
