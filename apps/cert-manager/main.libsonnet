local certManager = import 'github.com/VoyTechnology/home-libsonnet/cert-manager/main.libsonnet';
local cm = import 'github.com/jsonnet-libs/cert-manager-libsonnet/1.19/main.libsonnet';
local es = import 'github.com/jsonnet-libs/external-secrets-libsonnet/1.3/main.libsonnet';
local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.35/main.libsonnet';

// The operator first, then this homelab's config, namespace, secret and issuer on top.
certManager
{
  _config+:: {
    namespace: 'cert-manager',
    extraArgs+: {
      controller: [
        '--dns01-recursive-nameservers-only',
        '--dns01-recursive-nameservers=1.1.1.1:53',
        '--feature-gates=ExperimentalGatewayAPISupport=true',
        '--default-issuer-name=letsencrypt',
        '--default-issuer-kind=ClusterIssuer',
      ],
    },
    // Contact for Let's Encrypt expiry notices. Optional.
    acmeEmail: '',
    // Key in the `cluster-secrets` store holding the Cloudflare API token (property `token`).
    cloudflareTokenKey: 'cloudflare-cert-manager',
  },

  local cfg = $._config,

  // Flux never prunes the namespace, so removing the app keeps its secrets.
  namespace:
    k.core.v1.namespace.new(cfg.namespace)
    + k.core.v1.namespace.metadata.withAnnotations({ 'kustomize.toolkit.fluxcd.io/prune': 'disabled' }),

  // Cloudflare token for the DNS01 solver, fanned out from the cluster secret store.
  cloudflareSecret:
    es.nogroup.v1.externalSecret.new('cloudflare-secret')
    + es.nogroup.v1.externalSecret.metadata.withNamespace(cfg.namespace)
    + es.nogroup.v1.externalSecret.spec.secretStoreRef.withKind('ClusterSecretStore')
    + es.nogroup.v1.externalSecret.spec.secretStoreRef.withName('cluster-secrets')
    + es.nogroup.v1.externalSecret.spec.withData([
      es.nogroup.v1.externalSecret.spec.data.withSecretKey('token')
      + es.nogroup.v1.externalSecret.spec.data.remoteRef.withKey(cfg.cloudflareTokenKey)
      + es.nogroup.v1.externalSecret.spec.data.remoteRef.withProperty('token'),
    ]),

  letsencrypt:
    cm.nogroup.v1.clusterIssuer.new('letsencrypt')
    + cm.nogroup.v1.clusterIssuer.spec.acme.withServer('https://acme-v02.api.letsencrypt.org/directory')
    + (if cfg.acmeEmail != '' then cm.nogroup.v1.clusterIssuer.spec.acme.withEmail(cfg.acmeEmail) else {})
    + cm.nogroup.v1.clusterIssuer.spec.acme.privateKeySecretRef.withName('letsencrypt-prod')
    + cm.nogroup.v1.clusterIssuer.spec.acme.withSolvers([{
      dns01: {
        cnameStrategy: 'Follow',
        cloudflare: { apiTokenSecretRef: { name: 'cloudflare-secret', key: 'token' } },
      },
    }]),
}
