local home = import 'home/main.libsonnet';

// Secrets fanned out from the `cluster-secrets` store, read by Garage, its bootstrap Job and Mimir.
{
  garageSecret: home.secrets.fromShared($._config.namespace, $._config.secretName, {
    'rpc-secret': 'garage_rpc_secret',
    'admin-token': 'garage_admin_token',
  }),

  // The S3 key Garage imports and Mimir uses.
  garageS3KeySecret: home.secrets.fromShared($._config.namespace, $._config.s3KeySecretName, {
    'access-key-id': 'metrics_s3_access_key_id',
    'secret-access-key': 'metrics_s3_secret_access_key',
  }),
}
