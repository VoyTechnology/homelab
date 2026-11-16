local es = import 'github.com/jsonnet-libs/external-secrets-libsonnet/1.3/main.libsonnet';
local externalSecret = es.nogroup.v1.externalSecret;

{
  // The long-lived access token and public URL of Home Assistant. The token is read by Matter Hub, the
  // ServiceMonitor and the reload job; only the token goes through the cluster, the URL is the public one.
  tokenSecret:
    externalSecret.new($._config.tokenSecretName)
    + externalSecret.metadata.withNamespace($._config.namespace)
    + externalSecret.spec.withRefreshInterval('1h')
    + externalSecret.spec.secretStoreRef.withKind('ClusterSecretStore')
    + externalSecret.spec.secretStoreRef.withName('cluster-secrets')
    + externalSecret.spec.target.withName($._config.tokenSecretName)
    + externalSecret.spec.target.withCreationPolicy('Owner')
    + externalSecret.spec.target.withDeletionPolicy('Retain')
    + externalSecret.spec.withData([
      externalSecret.spec.data.withSecretKey('token')
      + externalSecret.spec.data.remoteRef.withKey('shared-secrets')
      + externalSecret.spec.data.remoteRef.withProperty('homeassistant_token'),
      externalSecret.spec.data.withSecretKey('url')
      + externalSecret.spec.data.remoteRef.withKey('shared-secrets')
      + externalSecret.spec.data.remoteRef.withProperty('homeassistant_url'),
    ]),
}
