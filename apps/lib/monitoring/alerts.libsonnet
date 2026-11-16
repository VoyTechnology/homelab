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
  summary: summary,
  severity: severity,
};

// A Grafana-managed rule: query A, then a threshold. Every expr here already filters to the
// failing series, so `* 0 + 1` turns each returned series into 1 and the threshold fires on it.
local grafanaRule(group, r, datasourceUid) = {
  uid: std.asciiLower(r.alert),
  title: r.alert,
  ruleGroup: group,
  folderUID: folder.uid,
  orgID: 1,
  condition: 'B',
  data: [
    {
      refId: 'A',
      relativeTimeRange: { from: 600, to: 0 },
      datasourceUid: datasourceUid,
      model: {
        refId: 'A',
        expr: '(%s) * 0 + 1' % r.expr,
        instant: true,
        range: false,
      },
    },
    {
      refId: 'B',
      datasourceUid: '__expr__',
      model: {
        refId: 'B',
        type: 'threshold',
        expression: 'A',
        conditions: [{ evaluator: { type: 'gt', params: [0] } }],
      },
    },
  ],
  'for': r.duration,
  noDataState: 'OK',
  execErrState: 'Error',
  labels: { severity: r.severity },
  annotations: { summary: r.summary },
};

{
  grafanaGroups(datasourceUid)::
    [
      {
        name: g.name,
        folderUid: folder.uid,
        interval: intervalSeconds,
        rules: [grafanaRule(g.name, r, datasourceUid) for r in g.rules],
      }
      for g in $.alertGroups
    ],

  alertGroups:: [
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
          'NodeNotReady',
          'kube_node_status_condition{condition="Ready",status="true"} == 0',
          '5m',
          'Node {{ $labels.node }} is not ready',
          'critical',
        ),
        rule(
          'PodCrashLooping',
          'increase(kube_pod_container_status_restarts_total[30m]) > 3',
          '5m',
          '{{ $labels.namespace }}/{{ $labels.pod }} is restarting repeatedly',
        ),
        rule(
          'PodNotRunning',
          'sum by (namespace, pod) (kube_pod_status_phase{phase=~"Pending|Failed|Unknown"}) > 0',
          '15m',
          '{{ $labels.namespace }}/{{ $labels.pod }} has not been running for 15m',
        ),
        rule(
          'DeploymentUnavailable',
          'kube_deployment_status_replicas_available < kube_deployment_spec_replicas',
          '15m',
          'Deployment {{ $labels.namespace }}/{{ $labels.deployment }} is missing replicas',
        ),
        rule(
          'StatefulSetNotReady',
          'kube_statefulset_status_replicas_ready < kube_statefulset_replicas',
          '15m',
          'StatefulSet {{ $labels.namespace }}/{{ $labels.statefulset }} is missing replicas',
        ),
      ],
    },
    {
      name: 'homelab.capacity',
      rules: [
        rule(
          'PersistentVolumeFillingUp',
          'kubelet_volume_stats_available_bytes / kubelet_volume_stats_capacity_bytes < 0.15',
          '15m',
          'Volume {{ $labels.namespace }}/{{ $labels.persistentvolumeclaim }} is over 85% full',
        ),
        rule(
          'PersistentVolumeAlmostFull',
          'kubelet_volume_stats_available_bytes / kubelet_volume_stats_capacity_bytes < 0.05',
          '5m',
          'Volume {{ $labels.namespace }}/{{ $labels.persistentvolumeclaim }} is over 95% full',
          'critical',
        ),
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
