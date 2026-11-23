// Scaling: replica counts and CPU/memory requests and limits.
{
  _config+:: {
    // Keyed by component, as the library reads them. Observed over 30 days: controller ~55Mi,
    // webhook ~37Mi, certController ~70Mi.
    resources: {
      controller: { requests: { cpu: '10m', memory: '64Mi' }, limits: { memory: '256Mi' } },
      webhook: { requests: { cpu: '10m', memory: '48Mi' }, limits: { memory: '128Mi' } },
      certController: { requests: { cpu: '10m', memory: '96Mi' }, limits: { memory: '128Mi' } },
    },
  },
}
