local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';
local configMap = k.core.v1.configMap;

// The mimir-mixin's recording rules (the ones the mixin dashboards query,
// e.g. cluster_namespace_job_route:cortex_request_duration_seconds:sum_rate)
// are never evaluated unless something loads them into the ruler. Build them
// here from the same base mixin config imported by apps/monitoring (see
// mixins.libsonnet there) so the recording rule names match exactly what the
// dashboards query. apps/monitoring layers a `dashboards_default_latency_mode:
// 'native'` override on top of this config, but that key only picks the
// default value of a dashboard template variable -- it doesn't affect which
// recording rules get generated (that's the separate record_native default,
// already true in the vendored mixin), so the rule names built here still
// match. Alerting rules are intentionally left out for now:
// alertmanager_enabled is false, and ruler.alertmanager-url points at
// a service that doesn't exist, so alert rules would just fail to notify.
local mimirMixinRecordingRules =
  (import 'mimir-mixin/config.libsonnet')
  + (import 'mimir-mixin/groups.libsonnet')
  + (import 'mimir-mixin/utils.libsonnet')
  + (import 'mimir-mixin/recording_rules.libsonnet');

// Same problem, same fix, for the kubernetes-mixin dashboards added in
// apps/monitoring/mixins.libsonnet: those dashboards (Compute
// Resources/*, Networking/*, Kubelet, ...) query recording rules like
// node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate
// and namespace_workload_pod:kube_pod_owner:relabel, not raw metrics --
// without the rules loaded into the ruler those queries (and the template
// variables built from them, e.g. Workload's $workload_type) just come back
// empty, even though the underlying cadvisor/kube-state-metrics data is
// fine. kubeletSelector/cadvisorSelector overrides must match
// apps/monitoring/mixins.libsonnet's exactly, since the rules
// themselves are job-selector-sensitive (e.g. node_cpu_hourly_cost has
// nothing to do with cadvisor, but node_namespace_pod_container:*
// aggregates straight off container_cpu_usage_seconds_total{cadvisorSelector}).
local kubernetesMixinRecordingRules =
  (import 'kubernetes-mixin/mixin.libsonnet') {
    _config+:: {
      kubeletSelector: 'job="integrations/kubernetes/kubelet"',
      cadvisorSelector: 'job="integrations/kubernetes/cadvisor"',
    },
  };

// Mimir's ruler reads per-tenant rule files from <ruler_local_directory>/<tenant>/.
// Multi-tenancy is disabled, so everything is written under Mimir's
// no-auth tenant (auth.no-auth-tenant default, "anonymous").
local tenant = 'anonymous';

// Distinct from the ruler's own scratch directory (ruler.rule-path, /rules)
// where it materializes rule groups pulled from this directory, and from
// /etc/mimir (the "overrides" ConfigMap mount) so this volume doesn't nest
// inside another ConfigMap's mount path.
local rulesDir = '/etc/mimir-rules';

{
  _config+:: { ruler_local_directory: rulesDir },

  recordingRules:
    configMap.new('mimir-recording-rules')
    + configMap.withDataMixin({
      'mimir-mixin.yaml': std.manifestYamlDoc({ groups: mimirMixinRecordingRules.prometheusRules.groups }),
      'kubernetes-mixin.yaml': std.manifestYamlDoc({ groups: kubernetesMixinRecordingRules.prometheusRules.groups }),
    }),

  ruler_deployment+: k.util.configMapVolumeMount($.recordingRules, rulesDir + '/' + tenant),
}
