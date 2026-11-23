// Scaling: replica counts and CPU/memory requests and limits.
{
  _config+:: {
    // Uses ~830-890Mi over 30 days and next to no CPU, apart from short bursts while consuming.
    resources: { requests: { cpu: '50m', memory: '1Gi' }, limits: { memory: '2Gi' } },
    // ~15Mi.
    redisResources: { requests: { cpu: '10m', memory: '32Mi' }, limits: { memory: '128Mi' } },
  },
}
