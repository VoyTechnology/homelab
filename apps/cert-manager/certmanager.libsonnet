local certManager = import 'github.com/VoyTechnology/home-libsonnet/cert-manager/main.libsonnet';
local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.35/main.libsonnet';

// The operator, with this homelab's flags and namespace.
certManager {
  controller_container+:: {
    resources+: { limits+: { memory: '256Mi' } },
    args+: [
      '--dns01-recursive-nameservers-only',
      '--dns01-recursive-nameservers=1.1.1.1:53',
      '--feature-gates=ExperimentalGatewayAPISupport=true',
      '--default-issuer-name=letsencrypt',
      '--default-issuer-kind=ClusterIssuer',
    ],
  },

  // Both use under 100Mi; unlimited, a leak could take the node down.
  cainjector_container+:: { resources+: { limits+: { memory: '256Mi' } } },

  // Flux never prunes the namespace, so removing the app keeps its secrets.
  namespace:
    k.core.v1.namespace.new($._config.namespace)
    + k.core.v1.namespace.metadata.withAnnotations({ 'kustomize.toolkit.fluxcd.io/prune': 'disabled' }),
}
