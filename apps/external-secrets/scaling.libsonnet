// Scaling: replica counts and CPU/memory requests and limits.
{
  _config+:: {
    // Keyed by component, as the library reads them.
    resources: {
      controller: { requests: { cpu: '10m', memory: '64Mi' }, limits: { memory: '256Mi' } },
      webhook: { requests: { cpu: '10m', memory: '32Mi' }, limits: { memory: '128Mi' } },
      certController: { requests: { cpu: '10m', memory: '32Mi' }, limits: { memory: '128Mi' } },
    },
  },
}
