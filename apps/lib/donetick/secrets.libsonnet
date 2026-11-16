local es = import 'github.com/jsonnet-libs/external-secrets-libsonnet/1.3/main.libsonnet';
local externalSecret = es.nogroup.v1.externalSecret;

{
  // The JWT signing secret (changing it logs everyone out) and the Telegram bot token.
  secrets:
    externalSecret.new($._config.secretName)
    + externalSecret.metadata.withNamespace($._config.namespace)
    + externalSecret.spec.withRefreshInterval('1h')
    + externalSecret.spec.secretStoreRef.withKind('ClusterSecretStore')
    + externalSecret.spec.secretStoreRef.withName('cluster-secrets')
    + externalSecret.spec.target.withName($._config.secretName)
    + externalSecret.spec.target.withCreationPolicy('Owner')
    + externalSecret.spec.target.withDeletionPolicy('Retain')
    + externalSecret.spec.withData([
      externalSecret.spec.data.withSecretKey('DT_JWT_SECRET')
      + externalSecret.spec.data.remoteRef.withKey('shared-secrets')
      + externalSecret.spec.data.remoteRef.withProperty('donetick_jwt_secret'),
      externalSecret.spec.data.withSecretKey('DT_TELEGRAM_TOKEN')
      + externalSecret.spec.data.remoteRef.withKey('shared-secrets')
      + externalSecret.spec.data.remoteRef.withProperty('donetick_telegram_token'),
    ]),
}
