local es = import 'github.com/jsonnet-libs/external-secrets-libsonnet/1.3/main.libsonnet';
local externalSecret = es.nogroup.v1.externalSecret;

// Secrets fanned out from the `cluster-secrets` store.
{
  // Key that Pocket ID encrypts its data with. Losing it makes the volume unreadable.
  encryptionKey:
    externalSecret.new('pocketid-encryption-key')
    + externalSecret.metadata.withNamespace($._config.namespace)
    + externalSecret.spec.secretStoreRef.withKind('ClusterSecretStore')
    + externalSecret.spec.secretStoreRef.withName('cluster-secrets')
    + externalSecret.spec.target.withName('pocketid-encryption-key')
    + externalSecret.spec.target.withCreationPolicy('Owner')
    + externalSecret.spec.target.withDeletionPolicy('Retain')
    + externalSecret.spec.withData([
      externalSecret.spec.data.withSecretKey('encryptionKey')
      + externalSecret.spec.data.remoteRef.withKey('shared-secrets')
      + externalSecret.spec.data.remoteRef.withProperty($._config.encryptionKeyProperty),
    ]),
}
