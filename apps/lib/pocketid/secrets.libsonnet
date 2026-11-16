local home = import 'home/main.libsonnet';

// Secrets fanned out from the `cluster-secrets` store.
{
  // Key that Pocket ID encrypts its data with. Losing it makes the volume unreadable.
  encryptionKey: home.secrets.fromShared($._config.namespace, 'pocketid-encryption-key', {
    encryptionKey: $._config.encryptionKeyProperty,
  }),
}
