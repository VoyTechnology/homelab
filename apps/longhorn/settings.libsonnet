// The chart's defaultSettings only apply on a fresh install, so settings are set as objects.
// Longhorn owns the Setting objects: never let Flux prune them.
{
  local setting(name, value) = {
    apiVersion: 'longhorn.io/v1beta2',
    kind: 'Setting',
    metadata: {
      name: name,
      namespace: $._config.namespace,
      annotations: { 'kustomize.toolkit.fluxcd.io/prune': 'disabled' },
    },
    value: value,
  },

  settings: {
    // Allow two replicas of a volume on one node (e.g. on its two disks) when no other node has room.
    replicaSoftAntiAffinity: setting('replica-soft-anti-affinity', 'true'),
  },
}
