(import '../../main.libsonnet')
+ {
  _config+:: {
    host: 'longhorn.bet1.bednarzak.com',
    // The 229G NVMe on s1-bet1 (mounted at /nvme); 20Gi kept free for the filesystem.
    extraDisks: {
      's1-bet1': { nvme: { path: '/nvme/longhorn', reservedBytes: 21474836480 } },
    },
  },
}
