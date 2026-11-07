{
  _config+:: {
    namespace: 'longhorn-system',
    // Helm release name; it ends up in the `app.kubernetes.io/instance` label, so keep what Argo used.
    release: 'longhorn',
    // Two replicas: there will not be more storage anytime soon.
    defaultReplicaCount: 2,
    // Specific to k3s.
    kubeletRootDir: '/var/lib/kubelet',
    // Host of the UI. Set per cluster.
    host: '',
    // Gateway the UI is served from, and the Pocket ID that guards it.
    gateway: { name: 'internal', namespace: 'envoy-gateway-system' },
    // In-cluster Service of Pocket ID (the PocketIDInstance's), used for the token call.
    pocketid: { service: 'pocket-id', namespace: 'pocketid', port: 1411 },
    oidcIssuer: 'https://login.bednarzak.com',
    // Pocket ID user group (a PocketIDUserGroup in the pocketid namespace) allowed to open the UI.
    // The UI can delete volumes, so only infra.
    allowedGroup: 'infra',
  },
}
