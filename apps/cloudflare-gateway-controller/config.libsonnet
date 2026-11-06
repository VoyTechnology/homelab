{
  _config+:: {
    namespace: 'cloudflare-gateway-system',
    // Names the Cloudflare tunnels and DNS records this cluster creates.
    clusterName: 'bet1',
    // Properties of the `shared-secrets` secret (the `cluster-secrets` store) holding the Cloudflare
    // credentials. The token needs Cloudflare Tunnel: Edit (account) and DNS: Edit (zone).
    apiTokenProperty: 'cloudflare_gateway_token',
    accountIdProperty: 'cloudflare_account_id',
  },
}
