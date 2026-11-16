local utils = import 'utils/main.libsonnet';

// Secrets fanned out from the `cluster-secrets` store.
{
  // Grafana Cloud credentials for Alloy.
  grafanaCloud: utils.secrets.fromShared('grafana-cloud', {
    token: 'grafana_cloud_token',
    user: 'grafana_cloud_user',
    'loki-user': 'grafana_cloud_loki_user',
    'remote-config-url': 'grafana_cloud_remote_config_url',
    'metrics-url': 'grafana_cloud_metrics_url',
    'logs-url': 'grafana_cloud_logs_url',
  }),
}
