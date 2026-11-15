{
  _config+:: {
    namespace: 'donetick',
    host: 'chores.bednarzak.com',
    // Pocket ID is the identity provider for login.
    oidcHost: 'login.bednarzak.com',
    pocketidNamespace: 'pocketid',
    // Same names as under Argo CD, so the existing data volume is adopted in place.
    storage+: { storageClassName: 'longhorn' },
  },
}
