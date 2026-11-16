local es = import 'github.com/jsonnet-libs/external-secrets-libsonnet/1.3/main.libsonnet';
local externalSecret = es.nogroup.v1.externalSecret;

// Secret key -> property of `shared-secrets`.
local secret(namespace, name, properties) =
  externalSecret.new(name)
  + externalSecret.metadata.withNamespace(namespace)
  + externalSecret.spec.withRefreshInterval('1h')
  + externalSecret.spec.secretStoreRef.withKind('ClusterSecretStore')
  + externalSecret.spec.secretStoreRef.withName('cluster-secrets')
  + externalSecret.spec.target.withName(name)
  + externalSecret.spec.target.withCreationPolicy('Owner')
  + externalSecret.spec.withData([
    externalSecret.spec.data.withSecretKey(key)
    + externalSecret.spec.data.remoteRef.withKey('shared-secrets')
    + externalSecret.spec.data.remoteRef.withProperty(properties[key])
    for key in std.objectFields(properties)
  ]);

// Secrets fanned out from the `cluster-secrets` store, read by Garage, its bootstrap Job and Mimir.
{
  garageSecret: secret($._config.namespace, $._config.secretName, {
    'rpc-secret': 'garage_rpc_secret',
    'admin-token': 'garage_admin_token',
  }),

  // The S3 key Garage imports and Mimir uses.
  garageS3KeySecret: secret($._config.namespace, $._config.s3KeySecretName, {
    'access-key-id': 'metrics_s3_access_key_id',
    'secret-access-key': 'metrics_s3_secret_access_key',
  }),
}
