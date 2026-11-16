// Scaling: replica counts and CPU/memory requests and limits. Everything runs as a single replica.
{
  matterhub+: {
    matterhub_container+:: {
      resources: {
        requests: { cpu: '100m', memory: '256Mi' },
        limits: { memory: '512Mi' },
      },
    },
  },
}
