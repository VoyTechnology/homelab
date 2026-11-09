(import '../../main.libsonnet')
+ {
  _config+:: {
    domain: 'bet1.bednarzak.com',
    // Pinned to the addresses MetalLB already handed out, so nothing moves (and the port-forward stays valid).
    internalAddress: '192.168.3.7',
    exposedAddress: '192.168.3.9',
    // Same node as Home Assistant and most backends, so tunnel traffic reaches them from a pod address.
    tunnelNode: 's1-bet1',
  },
}
