// Scaling: replica counts and CPU/memory requests and limits.
{
  _config+:: {
    // The JVM sits at a steady ~2Gi resident (the heap is preallocated) and ~60m CPU.
    resources: { requests: { cpu: '100m', memory: '2304Mi' }, limits: { memory: '3Gi' } },
    // Idle, but peaks at ~1.4Gi while a backup runs.
    backupResources: { requests: { cpu: '10m', memory: '256Mi' }, limits: { memory: '2Gi' } },
  },
}
