// Extra Longhorn disks per node. Longhorn owns the Node objects, so only the disks listed here
// are applied (server-side apply merges them with the default disk) and Flux never prunes the Node.
{
  nodes: {
    [node]: {
      apiVersion: 'longhorn.io/v1beta2',
      kind: 'Node',
      metadata: {
        name: node,
        namespace: $._config.namespace,
        annotations: { 'kustomize.toolkit.fluxcd.io/prune': 'disabled' },
      },
      spec: {
        disks: {
          [disk]: {
            path: $._config.extraDisks[node][disk].path,
            diskType: 'filesystem',
            allowScheduling: true,
            evictionRequested: false,
            storageReserved: $._config.extraDisks[node][disk].reservedBytes,
            tags: std.get($._config.extraDisks[node][disk], 'tags', []),
          }
          for disk in std.objectFields($._config.extraDisks[node])
        },
      },
    }
    for node in std.objectFields($._config.extraDisks)
  },
}
