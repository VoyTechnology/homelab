local flux = import 'github.com/jsonnet-libs/fluxcd-libsonnet/2.9.4/main.libsonnet';

// Continuous reconciliation of <cluster>/ in homelab-manifests into the cluster.
{
  local cluster = std.split($._cluster, '/')[1],
  _cluster:: std.extVar('tanka.dev/environment').metadata.name,

  gitRepository:
    flux.source.v1.gitRepository.new('homelab-manifests')
    + flux.source.v1.gitRepository.metadata.withNamespace($._namespace)
    + flux.source.v1.gitRepository.spec.withUrl($._config.repo)
    + flux.source.v1.gitRepository.spec.withInterval($._config.interval)
    + flux.source.v1.gitRepository.spec.ref.withBranch($._config.branch)
    + flux.source.v1.gitRepository.spec.secretRef.withName($._config.secret),

  kustomization:
    flux.kustomize.v1.kustomization.new('homelab-manifests')
    + flux.kustomize.v1.kustomization.metadata.withNamespace($._namespace)
    + flux.kustomize.v1.kustomization.spec.withInterval($._config.interval)
    + flux.kustomize.v1.kustomization.spec.withPath('./' + cluster)
    // Anything removed from the manifests repo is removed from the cluster.
    + flux.kustomize.v1.kustomization.spec.withPrune(true)
    + flux.kustomize.v1.kustomization.spec.sourceRef.withKind('GitRepository')
    + flux.kustomize.v1.kustomization.spec.sourceRef.withName('homelab-manifests'),

  _namespace:: std.extVar('tanka.dev/environment').spec.namespace,
}
