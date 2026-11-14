// Scaling: replica counts and CPU/memory requests and limits.
{
  external_dns_container+:: {
    resources: { requests: { cpu: '10m', memory: '32Mi' }, limits: { memory: '128Mi' } },
  },
}
