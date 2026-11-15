local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.35/main.libsonnet';

{
  // Flux never prunes the namespace, so removing the app keeps it.
  namespace:
    k.core.v1.namespace.new($._config.namespace)
    + k.core.v1.namespace.metadata.withAnnotations({ 'kustomize.toolkit.fluxcd.io/prune': 'disabled' }),
}
