local metallb = import 'github.com/jsonnet-libs/metallb-libsonnet/0.14/main.libsonnet';
local ipAddressPool = metallb.metallb.v1beta1.ipAddressPool;
local l2Advertisement = metallb.metallb.v1beta1.l2Advertisement;

// The pool Services draw from, announced over layer 2.
{
  homelabIpAddressPool:
    ipAddressPool.new('homelab-ip-pool')
    + ipAddressPool.metadata.withNamespace($._config.namespace)
    + ipAddressPool.spec.withAddresses($._config.addresses),

  homelabL2Advertisement:
    l2Advertisement.new('homelab-l2-advertisement')
    + l2Advertisement.metadata.withNamespace($._config.namespace)
    + l2Advertisement.spec.withIpAddressPools([$.homelabIpAddressPool.metadata.name]),
}
