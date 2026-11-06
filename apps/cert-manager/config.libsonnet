{
  _config+:: {
    namespace: 'cert-manager',
    // Key in the `cluster-secrets` store holding the Cloudflare API token (property `token`).
    cloudflareTokenKey: 'cloudflare-cert-manager',
    // Contact for Let's Encrypt expiry notices. Optional.
    acmeEmail: '',
  },
}
