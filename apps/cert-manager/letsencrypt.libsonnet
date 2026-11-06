local cm = import 'github.com/jsonnet-libs/cert-manager-libsonnet/1.19/main.libsonnet';
local clusterIssuer = cm.nogroup.v1.clusterIssuer;

// The default issuer: Let's Encrypt with DNS01 through Cloudflare.
{
  _config+:: {
    // Contact for Let's Encrypt expiry notices. Optional.
    acmeEmail: '',
  },

  letsencrypt:
    clusterIssuer.new('letsencrypt')
    + clusterIssuer.spec.acme.withServer('https://acme-v02.api.letsencrypt.org/directory')
    + (if $._config.acmeEmail != '' then clusterIssuer.spec.acme.withEmail($._config.acmeEmail) else {})
    + clusterIssuer.spec.acme.privateKeySecretRef.withName('letsencrypt-prod')
    + clusterIssuer.spec.acme.withSolvers([{
      dns01: {
        cnameStrategy: 'Follow',
        cloudflare: { apiTokenSecretRef: { name: $.cloudflareSecret.metadata.name, key: 'token' } },
      },
    }]),
}
