(import '../../main.libsonnet')
+ {
  _config+:: {
    host: 'longhorn.bet1.bednarzak.com',
    // s1-bet1: the existing default disk (values as in the live Node) plus the 229G NVMe (20Gi kept free).
    disks: {
      's1-bet1': {
        'default-disk-cad5dc980083830': { path: '/var/lib/longhorn/', reservedBytes: 73037756006 },
        nvme: { path: '/nvme/longhorn', reservedBytes: 21474836480 },
      },
    },
  },
}
