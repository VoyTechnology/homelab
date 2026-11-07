{
  _config+:: {
    // Shared by the Envoy control plane, the Cloudflare controller and every gateway.
    namespace: 'gateway-system',
    // The wildcard certificate and listeners cover `*.<domain>`. Set per cluster.
    domain: '',
    // MetalLB addresses of the gateways. Set per cluster: the external one is port-forwarded from the
    // router, the internal one is only reachable on the local network.
    internalAddress: '',
    exposedAddress: '',
    // Address external-dns publishes for the exposed gateway (the public IP). Empty uses the gateway's own.
    exposedDnsTarget: '',
    // MetalLB pool the gateways draw from (when no fixed address is set).
    addressPool: 'homelab-ip-pool',
    // The control plane moved here from envoy-gateway-system, so its TLS Secrets must be created once.
    // Turn off after the first sync: the Job deletes itself and would be recreated on every reconcile.
    certgen: true,

    // Names the Cloudflare tunnels and DNS records this cluster creates.
    clusterName: 'bet1',
    // Properties of the `shared-secrets` secret (the `cluster-secrets` store) holding the Cloudflare
    // credentials. The token needs Cloudflare Tunnel: Edit (account) and DNS: Edit (zone).
    apiTokenProperty: 'external_gateway_cloudflare_token',
    accountIdProperty: 'cloudflare_account_id',
  },
}
