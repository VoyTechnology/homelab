// Scaling: replica counts and CPU/memory requests and limits. Everything runs as a single replica.
// Observed over 30 days.
{
  // Resident memory peaks at ~1.65Gi; the working set reads higher (~2Gi) only because of page cache.
  homeassistant+: {
    haContainer+:: {
      resources: {
        requests: { cpu: '100m', memory: '1792Mi' },
        limits: { memory: '3Gi' },
      },
    },
  },

  // ~210Mi.
  matterhub+: {
    matterhub_container+:: {
      resources: {
        requests: { cpu: '100m', memory: '256Mi' },
        limits: { memory: '512Mi' },
      },
    },
  },

  // ~220Mi.
  matterServer+: {
    matter_container+:: {
      resources: {
        requests: { cpu: '10m', memory: '256Mi' },
        limits: { memory: '512Mi' },
      },
    },
  },

  // ~14Mi.
  otbr+: {
    otbr_container+:: {
      resources: {
        requests: { cpu: '10m', memory: '32Mi' },
        limits: { memory: '128Mi' },
      },
    },
  },
}
