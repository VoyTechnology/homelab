local es = import 'github.com/jsonnet-libs/external-secrets-libsonnet/1.3/main.libsonnet';
local externalSecret = es.nogroup.v1.externalSecret;

// Secrets fanned out from the `cluster-secrets` store.
{
  // Credentials the GatewayClass points at, under the keys the controller expects.
  cloudflareSecret:
    externalSecret.new('cloudflare-gateway-credentials')
    + externalSecret.metadata.withNamespace($._config.namespace)
    + externalSecret.spec.secretStoreRef.withKind('ClusterSecretStore')
    + externalSecret.spec.secretStoreRef.withName('cluster-secrets')
    + externalSecret.spec.target.withName('cloudflare-gateway-credentials')
    + externalSecret.spec.withData([
      externalSecret.spec.data.withSecretKey(key)
      + externalSecret.spec.data.remoteRef.withKey('shared-secrets')
      + externalSecret.spec.data.remoteRef.withProperty(property)
      for kv in [
        ['CLOUDFLARE_API_TOKEN', $._config.apiTokenProperty],
        ['CLOUDFLARE_ACCOUNT_ID', $._config.accountIdProperty],
      ]
      for key in [kv[0]]
      for property in [kv[1]]
    ]),
}
