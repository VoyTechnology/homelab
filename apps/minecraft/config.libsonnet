{
  _config+:: {
    namespace: 'minecraft',
    // Hostname of the BlueMap web map, served through the Cloudflare Gateway.
    mapHost: 'skynet-map.voy.technology',
    // Where the backup sidecar copies the archives to, on the node the pod is pinned to.
    backupHostPath: '/storage/backups/minecraft/daily',
    backupRetentionDays: 14,
  },
}
