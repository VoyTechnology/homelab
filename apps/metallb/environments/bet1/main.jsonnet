(import '../../main.libsonnet')
+ {
  _config+:: {
    // Matches homelabIpAddressPool in argo/clusters/bet1.yaml.
    addresses: ['192.168.3.6-192.168.3.254'],
  },
}
