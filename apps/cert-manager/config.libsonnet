{
  _config+:: {
    namespace: 'cert-manager',
    // Property of the `shared-secrets` secret (the `cluster-secrets` store) holding the Cloudflare API token.
    cloudflareTokenProperty: 'cloudflare_cert_manager_token',
    // Contact for Let's Encrypt expiry notices. Optional.
    acmeEmail: '',
  },
}
