{
  _config+:: {
    // External Secrets Operator is cluster-wide, so it lives in kube-system (an
    // existing namespace Flux must not manage or prune).
    namespace: 'kube-system',
  },
}
