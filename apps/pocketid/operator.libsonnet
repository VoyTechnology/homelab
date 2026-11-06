local operator = import 'github.com/VoyTechnology/home-libsonnet/pocket-id-operator/main.libsonnet';
local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.35/main.libsonnet';

// The operator, in the namespace of the instance.
operator {
  // Flux never prunes the namespace, so removing the app keeps its volumes.
  namespace:
    k.core.v1.namespace.new($._config.namespace)
    + k.core.v1.namespace.metadata.withAnnotations({ 'kustomize.toolkit.fluxcd.io/prune': 'disabled' }),
}
