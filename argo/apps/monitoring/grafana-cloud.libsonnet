// Pulls the Grafana Cloud credentials (used by Grafana's OAuth config and
// by Alloy's remote_write) out of the shared-secrets store into a
// grafana-cloud Secret. external-secrets.io isn't a type k8s-libsonnet
// generates (it's a CRD, not core Kubernetes), so this is a plain
// manifest object -- same pattern as grafana.libsonnet's httpRoute.
local config = import 'config.libsonnet';

// secretKey -> shared-secrets property name.
local keys = {
  token: 'grafana_cloud_token',
  user: 'grafana_cloud_user',
  'loki-user': 'grafana_cloud_loki_user',
  'remote-config-url': 'grafana_cloud_remote_config_url',
  'metrics-url': 'grafana_cloud_metrics_url',
  'logs-url': 'grafana_cloud_logs_url',
  'oauth-client-id': 'grafana_auth_client_id',
  'oauth-client-secret': 'grafana_auth_client_secret',
};

config + {
  grafana_cloud_external_secret: {
    apiVersion: 'external-secrets.io/v1',
    kind: 'ExternalSecret',
    metadata: {
      name: 'grafana-cloud',
    },
    spec: {
      refreshInterval: '1h',
      secretStoreRef: {
        kind: 'ClusterSecretStore',
        name: 'cluster-secrets',
      },
      target: {
        name: 'grafana-cloud',
        creationPolicy: 'Owner',
      },
      data: [
        { secretKey: secretKey, remoteRef: { key: 'shared-secrets', property: keys[secretKey] } }
        for secretKey in std.objectFields(keys)
      ],
    },
  },
}
