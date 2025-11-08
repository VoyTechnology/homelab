local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';

local source = helm.new(
  'gpu-operator',
  repoURL="https://helm.ngc.nvidia.com/nvidia",
  chart="gpu-operator",
  targetRevision="v25.10.0",
  values={
    driver: { version: '{{ .metadata["gpu.nvidia/driverversion"] | default "" }}' },
    nodeSelector: '{{ .metadata["gpu.nvidia/nodeselector"] | default {} }}'
  }
);

appset.new('gpu-operator', 'gpu-operator')
+ appset.addSource(source)
