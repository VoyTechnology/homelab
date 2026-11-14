// Scaling: replica counts and CPU/memory requests and limits.
{
  _config+:: {
    // Two replicas: there will not be more storage anytime soon.
    defaultReplicaCount: 2,
  },
}
