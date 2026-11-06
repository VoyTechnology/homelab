{
  _config+:: {
    // Also holds the operator, as before the move to Flux, so the instance and its PVC stay in place.
    namespace: 'pocketid',
    host: 'login.bednarzak.com',
    // Name of the PocketIDInstance. The operator derives the Service and the PVC from it. Do not change.
    instanceName: 'pocket-id',
    // Property of the `shared-secrets` secret (the `cluster-secrets` store) holding the encryption key.
    encryptionKeyProperty: 'pocketid_encryption_key',
  },
}
