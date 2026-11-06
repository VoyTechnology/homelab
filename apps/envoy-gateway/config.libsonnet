{
  _config+:: {
    // Created by Argo CD before the move to Flux, then kept by Flux (never pruned).
    namespace: 'envoy-gateway-system',
    // The wildcard certificates and listeners cover `*.<domain>`. Set per cluster.
    domain: '',
    // MetalLB addresses of the gateways. Set per cluster: the external one is port-forwarded from the
    // router, the internal one is only reachable on the local network.
    internalAddress: '',
    exposedAddress: '',
    // Address external-dns publishes for the exposed gateway (the public IP). Empty uses the gateway's own.
    exposedDnsTarget: '',
    // MetalLB pool the gateways draw from (when no fixed address is set).
    addressPool: 'homelab-ip-pool',
    // The certgen Job is only needed on a fresh install; the control plane Secrets already exist here.
    certgen: false,
  },
}
