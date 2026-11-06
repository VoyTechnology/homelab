{
  _config+:: {
    namespace: 'gateway-system',
    // Names the Cloudflare tunnels and DNS records this cluster creates.
    clusterName: 'bet1',
    // Properties of the `shared-secrets` secret (the `cluster-secrets` store) holding the Cloudflare
    // credentials. The token needs Cloudflare Tunnel: Edit (account) and DNS: Edit (zone).
    apiTokenProperty: 'external_gateway_cloudflare_token',
    accountIdProperty: 'cloudflare_account_id',
    // Namespaces whose Gateways may use the credentials above (a ReferenceGrant each).
    gatewayNamespaces: ['pocketid'],
  },
}
