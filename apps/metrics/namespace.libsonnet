// The namespace itself comes from the Mimir library. Also holds what Argo CD created before the move to Flux.
{
  namespace+: {
    metadata+: { annotations+: { 'kustomize.toolkit.fluxcd.io/prune': 'disabled' } },
  },
}
