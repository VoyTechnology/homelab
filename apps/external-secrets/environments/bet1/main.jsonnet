// External Secrets Operator is cluster-wide, so it lives in kube-system (an
// existing namespace Flux must not manage or prune).
(import '../../main.libsonnet') {
  _config+:: { namespace: 'kube-system' },
}
