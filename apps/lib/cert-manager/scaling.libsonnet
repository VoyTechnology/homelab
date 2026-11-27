// Scaling: replica counts and CPU/memory requests and limits.
// Observed over 30 days: controller ~55Mi, cainjector ~110Mi (peak 150Mi), webhook ~35Mi, all
// around 1m CPU. Limits stay in place so a leak cannot take the node down.
{
  controller_container+:: {
    resources+: { requests+: { cpu: '10m', memory: '64Mi' }, limits+: { memory: '256Mi' } },
  },
  cainjector_container+:: {
    resources+: { requests+: { cpu: '10m', memory: '128Mi' }, limits+: { memory: '256Mi' } },
  },
  webhook_container+:: {
    resources+: { requests+: { cpu: '10m', memory: '48Mi' }, limits+: { memory: '128Mi' } },
  },
}
