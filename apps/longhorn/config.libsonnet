{
  _config+:: {
    namespace: 'longhorn-system',
    // Helm release name; it ends up in the `app.kubernetes.io/instance` label, so keep what Argo used.
    release: 'longhorn',
    // Two replicas: there will not be more storage anytime soon.
    defaultReplicaCount: 2,
    // Specific to k3s.
    kubeletRootDir: '/var/lib/kubelet',
    // Host of the UI. Set per cluster.
    host: '',
  },
}
