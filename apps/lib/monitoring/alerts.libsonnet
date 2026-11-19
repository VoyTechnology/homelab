// Alert rules, defined once as `alertGroups` and rendered as Grafana-managed rules for two places:
//   - the local Grafana, provisioned from a ConfigMap and evaluated on the local Mimir ("Metrics");
//   - Grafana Cloud, pushed by .github/workflows/grafana-alerts.yml from `cloudAlerts` (Cloud
//     evaluates them on the series that alloy-config.alloy's cloud_filter ships, so they still fire
//     when the cluster is down). Only use metrics that pass that filter.
local k = import 'ksonnet-util/kausal.libsonnet';

local folder = { uid: 'homelab', title: 'Homelab' };
local intervalSeconds = 60;

local rule(alert, expr, duration, summary, severity='warning') = {
  alert: alert,
  expr: expr,
  duration: duration,
  labels: { severity: severity },
  annotations: { summary: summary },
};

// Prometheus alerts from a mixin, in the same shape. Grafana templates expose the query value as
// $values.A.Value rather than $value.
local fromMixin(r) = {
  alert: r.alert,
  expr: std.stripChars(r.expr, '\n'),
  duration: r['for'],
  labels: r.labels,
  annotations: {
    [name]: std.strReplace(r.annotations[name], '$value', '$values.A.Value')
    for name in std.objectFields(r.annotations)
  },
};

// The kubernetes-mixin alerts that only need raw kube-state-metrics or kubelet series, which
// cloud_filter ships. The rest query recording rules that exist only in the local Mimir, or
// control-plane components that are not scraped on k3s.
local mixinAlerts = [
  'KubePodCrashLooping',
  'KubeDeploymentReplicasMismatch',
  'KubeStatefulSetReplicasMismatch',
  'KubeDaemonSetRolloutStuck',
  'KubeContainerWaiting',
  'KubePersistentVolumeFillingUp',
  'KubePersistentVolumeErrors',
  'KubeNodeNotReady',
  'KubeNodePressure',
];

local mixinGroups = [
  {
    name: g.name,
    rules: [fromMixin(r) for r in g.rules if std.member(mixinAlerts, r.alert)],
  }
  for g in (import 'mixins.libsonnet').kubernetes.prometheusAlerts.groups
  if std.length([r for r in g.rules if std.member(mixinAlerts, r.alert)]) > 0
];

// A Grafana-managed rule: the query as A, then a threshold on it. Every expr already filters to the
// failing series, so any returned series is firing; the threshold is below any value, which keeps
// the real value available to the templates as $values.A.Value.
// A group can hold the same alert twice with different severities (the mixin does), so those
// get the severity in the title.
local grafanaRule(group, r, datasourceUid, duplicate) =
  local title = if duplicate then '%s (%s)' % [r.alert, r.labels.severity] else r.alert;
  {
    uid: std.strReplace(std.strReplace(std.asciiLower(title), ' (', '-'), ')', ''),
    title: title,
    ruleGroup: group,
    folderUID: folder.uid,
    orgID: 1,
    condition: 'B',
    data: [
      {
        refId: 'A',
        relativeTimeRange: { from: 600, to: 0 },
        datasourceUid: datasourceUid,
        model: { refId: 'A', expr: r.expr, instant: true, range: false },
      },
      {
        refId: 'B',
        datasourceUid: '__expr__',
        model: {
          refId: 'B',
          type: 'threshold',
          expression: 'A',
          conditions: [{ evaluator: { type: 'gt', params: [-1e300] } }],
        },
      },
    ],
    'for': r.duration,
    noDataState: 'OK',
    execErrState: 'Error',
    labels: r.labels,
    annotations: r.annotations,
  };

{
  grafanaGroups(datasourceUid)::
    [
      {
        name: g.name,
        folderUid: folder.uid,
        interval: intervalSeconds,
        rules: [
          grafanaRule(
            g.name,
            r,
            datasourceUid,
            std.length([o for o in g.rules if o.alert == r.alert]) > 1,
          )
          for r in g.rules
        ],
      }
      for g in $.alertGroups
    ],

  alertGroups:: mixinGroups + [
    {
      name: 'homelab.availability',
      rules: [
        rule(
          'TargetDown',
          'up == 0',
          '10m',
          '{{ $labels.job }} target {{ $labels.instance }} is down',
          'critical',
        ),
        rule(
          'PodNotRunning',
          'sum by (namespace, pod) (kube_pod_status_phase{phase=~"Pending|Failed|Unknown"}) > 0',
          '15m',
          '{{ $labels.namespace }}/{{ $labels.pod }} has not been running for 15m',
        ),
      ],
    },
    {
      name: 'homelab.flux',
      rules: [
        // Suspended objects are left out on purpose, they are not meant to reconcile.
        rule(
          'FluxResourceNotReady',
          'gotk_resource_info{ready=~"False|Unknown", suspended!="true"} == 1',
          '2h',
          'Flux {{ $labels.name }} has not been Ready for 2h',
        ),
        // Reconciles run every 1-10m, so 3h without one means the controller or the object is stuck.
        rule(
          'FluxReconcileStalled',
          'increase(gotk_reconcile_duration_seconds_count{kind=~"Kustomization|HelmRelease|GitRepository"}[3h]) == 0',
          '5m',
          'Flux {{ $labels.name }} has not reconciled for 3h',
          'critical',
        ),
      ],
    },
    {
      name: 'homelab.capacity',
      rules: [
        rule(
          'NodeDiskFillingUp',
          |||
            node_filesystem_avail_bytes{fstype!~"tmpfs|overlay|squashfs"}
            / node_filesystem_size_bytes{fstype!~"tmpfs|overlay|squashfs"} < 0.10
          |||,
          '15m',
          'Filesystem {{ $labels.mountpoint }} on {{ $labels.instance }} is over 90% full',
        ),
        rule(
          'NodeMemoryLow',
          'node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes < 0.10',
          '15m',
          'Node {{ $labels.instance }} has under 10% memory available',
        ),
      ],
    },
  ],

  // File provisioning for the local Grafana. Its "Metrics" datasource has the uid set in grafana.libsonnet.
  grafanaAlertRules: k.core.v1.configMap.new('grafana-alert-rules', {
    // Grafana expands $VAR in provisioning files, so escape the $ of the $labels templates.
    'homelab.yaml': std.strReplace(std.manifestYamlDoc({
      apiVersion: 1,
      groups: [
        {
          orgId: 1,
          name: g.name,
          folder: folder.title,
          interval: '1m',
          rules: [
            r { orgID:: null, ruleGroup:: null, folderUID:: null }
            for r in g.rules
          ],
        }
        for g in $.grafanaGroups($._config.metricsDatasourceUid)
      ],
    }), '$', '$$'),
  }),

  grafana+: {
    grafana_deployment+: k.util.configMapVolumeMount(
      $.grafanaAlertRules,
      '/etc/grafana/provisioning/alerting',
    ),
  },

  // For Grafana Cloud: tk eval -e cloudAlerts, consumed by scripts/push-grafana-alerts.sh.
  cloudAlerts:: {
    folder: folder,
    groups: $.grafanaGroups($._config.cloudDatasourceUid),
  },
}
