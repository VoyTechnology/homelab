{
  _config+:: {
    namespace: 'longhorn-system',
    // Helm release name; it ends up in the `app.kubernetes.io/instance` label, so keep what Argo used.
    release: 'longhorn',
    // Disks Flux applies to a node: { <node>: { <disk>: { path, reservedBytes, tags } } }. List the
    // existing default disk too, with its live name and values, so it is kept. Paths must exist. Set per cluster.
    disks: {},
    // Specific to k3s.
    kubeletRootDir: '/var/lib/kubelet',
    // Host of the UI. Set per cluster.
    host: '',
    // Gateway the UI is served from, and the Pocket ID that guards it.
    gateway: { name: 'internal', namespace: 'gateway-system' },
    // In-cluster Service of Pocket ID (the PocketIDInstance's), used for the token call.
    pocketid: { service: 'pocket-id', namespace: 'pocketid', port: 1411 },
    oidcIssuer: 'https://login.bednarzak.com',
    // Pocket ID user group (a PocketIDUserGroup in the pocketid namespace) allowed to open the UI.
    // The UI can delete volumes, so only infra.
    allowedGroup: 'infra',
  },
}
