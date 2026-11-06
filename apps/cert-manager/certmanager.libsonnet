local certManager = import 'github.com/VoyTechnology/home-libsonnet/cert-manager/main.libsonnet';
local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.35/main.libsonnet';

// The operator, with this homelab's flags and namespace.
certManager {
  _config+:: {
    namespace: 'cert-manager',
  },

  controller_container+:: {
    args+: [
      '--dns01-recursive-nameservers-only',
      '--dns01-recursive-nameservers=1.1.1.1:53',
      '--feature-gates=ExperimentalGatewayAPISupport=true',
      '--default-issuer-name=letsencrypt',
      '--default-issuer-kind=ClusterIssuer',
    ],
  },

  // Flux never prunes the namespace, so removing the app keeps its secrets.
  namespace:
    k.core.v1.namespace.new($._config.namespace)
    + k.core.v1.namespace.metadata.withAnnotations({ 'kustomize.toolkit.fluxcd.io/prune': 'disabled' }),
}
