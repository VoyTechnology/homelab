// Scaling: replica counts and CPU/memory requests and limits.
{
  _config+:: {
    // Uses ~50-60Mi and next to no CPU.
    resources: { requests: { cpu: '10m', memory: '64Mi' }, limits: { memory: '128Mi' } },
  },
}
