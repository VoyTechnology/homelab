local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';

local source = helm.new(
  'gpu-operator',
  repoURL="https://helm.ngc.nvidia.com/nvidia",
  chart="gpu-operator",
  targetRevision="v25.10.0",
  values={
    driver: { version: '{{ index .metadata "gpu.nvidia/driverversion" | default "" }}' },
    nodeSelector: '{{ index .metadata "gpu.nvidia/nodeselector" | toYaml }}'
  }
);

appset.new('gpu-operator', 'gpu-operator')
+ appset.addSource(source)
