// Scaling: replica counts and CPU/memory requests and limits.
local small = { requests: { cpu: '10m', memory: '32Mi' }, limits: { memory: '128Mi' } };
// Short-lived init containers that only copy files.
local copy = { limits: { memory: '64Mi' } };

// The speaker pod runs seven containers, most defined inline by the library, so size them by name.
local bySize = {
  speaker: small,
  frr: small,
  reloader: { requests: { cpu: '5m', memory: '16Mi' }, limits: { memory: '64Mi' } },
  'frr-metrics': { requests: { cpu: '5m', memory: '16Mi' }, limits: { memory: '64Mi' } },
  'cp-frr-files': copy,
  'cp-reloader': copy,
  'cp-metrics': copy,
};
local sized(cs) = [c { resources: bySize[c.name] } for c in cs];

{
  metallb_controller_container+:: { resources: small },

  metallbSpeakerDaemonSet+: { spec+: { template+: { spec+: {
    containers: sized(super.containers),
    initContainers: sized(super.initContainers),
  } } } },
}
