// Scaling: replica counts and CPU/memory requests and limits.
{
  external_dns_container+:: {
    // Uses ~50Mi, so the old 32Mi request was too low.
    resources: { requests: { cpu: '10m', memory: '64Mi' }, limits: { memory: '128Mi' } },
  },
}
