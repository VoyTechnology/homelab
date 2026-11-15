local es = import 'github.com/jsonnet-libs/external-secrets-libsonnet/1.3/main.libsonnet';
local externalSecret = es.nogroup.v1.externalSecret;

{
  // Django's secret key, shared by every pod. Changing it logs everyone out, so it comes from the store.
  secretKey:
    externalSecret.new($._config.secretKeyName)
    + externalSecret.metadata.withNamespace($._config.namespace)
    + externalSecret.spec.withRefreshInterval('1h')
    + externalSecret.spec.secretStoreRef.withKind('ClusterSecretStore')
    + externalSecret.spec.secretStoreRef.withName('cluster-secrets')
    + externalSecret.spec.target.withName($._config.secretKeyName)
    + externalSecret.spec.target.withCreationPolicy('Owner')
    + externalSecret.spec.target.withDeletionPolicy('Retain')
    + externalSecret.spec.withData([
      externalSecret.spec.data.withSecretKey($._config.secretKeyKey)
      + externalSecret.spec.data.remoteRef.withKey('shared-secrets')
      + externalSecret.spec.data.remoteRef.withProperty('paperless_secret_key'),
    ]),
}
