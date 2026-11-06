local es = import 'github.com/jsonnet-libs/external-secrets-libsonnet/1.3/main.libsonnet';
local externalSecret = es.nogroup.v1.externalSecret;

// Secrets fanned out from the `cluster-secrets` store.
{
  // Cloudflare token for the DNS01 solver.
  cloudflareSecret:
    externalSecret.new('cloudflare-secret')
    + externalSecret.metadata.withNamespace($._config.namespace)
    + externalSecret.spec.secretStoreRef.withKind('ClusterSecretStore')
    + externalSecret.spec.secretStoreRef.withName('cluster-secrets')
    + externalSecret.spec.withData([
      externalSecret.spec.data.withSecretKey('token')
      + externalSecret.spec.data.remoteRef.withKey('shared-secrets')
      + externalSecret.spec.data.remoteRef.withProperty($._config.cloudflareTokenProperty),
    ]),
}
