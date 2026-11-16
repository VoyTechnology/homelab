local es = import 'github.com/jsonnet-libs/external-secrets-libsonnet/1.3/main.libsonnet';
local externalSecret = es.nogroup.v1.externalSecret;

// Secret key -> property of `shared-secrets`.
local properties = {
  token: 'grafana_cloud_token',
  user: 'grafana_cloud_user',
  'loki-user': 'grafana_cloud_loki_user',
  'remote-config-url': 'grafana_cloud_remote_config_url',
  'metrics-url': 'grafana_cloud_metrics_url',
  'logs-url': 'grafana_cloud_logs_url',
};

// Secrets fanned out from the `cluster-secrets` store.
{
  // Grafana Cloud credentials for Alloy.
  grafanaCloud:
    externalSecret.new('grafana-cloud')
    + externalSecret.metadata.withNamespace($._config.namespace)
    + externalSecret.spec.withRefreshInterval('1h')
    + externalSecret.spec.secretStoreRef.withKind('ClusterSecretStore')
    + externalSecret.spec.secretStoreRef.withName('cluster-secrets')
    + externalSecret.spec.target.withName('grafana-cloud')
    + externalSecret.spec.target.withCreationPolicy('Owner')
    + externalSecret.spec.withData([
      externalSecret.spec.data.withSecretKey(key)
      + externalSecret.spec.data.remoteRef.withKey('shared-secrets')
      + externalSecret.spec.data.remoteRef.withProperty(properties[key])
      for key in std.objectFields(properties)
    ]),
}
