// The server itself: Paper with Geyser (Bedrock), the BlueMap web map, pinned to the node holding its data.
{
  minecraft_env+:: {
    TYPE: 'PAPER',
    VERSION: 'LATEST',
    MOTD: 'Welcome to Skynet 3!',
    MEMORY: '1024M',
    MAX_BUILD_HEIGHT: '320',
    LEVEL: 'world',
    MODRINTH_DOWNLOAD_DEPENDENCIES: 'none',
  },

  ports+:: {
    // Geyser, for Bedrock players.
    bedrock: { port: 19132, protocol: 'UDP', serviceType: 'LoadBalancer' },
    // BlueMap, reached through the HTTPRoute.
    map: { port: 8100, protocol: 'TCP', serviceType: 'ClusterIP' },
  },

  // Keep the addresses the router and DNS point at.
  minecraftServices+: {
    minecraft+: { metadata+: { annotations+: { 'metallb.io/loadBalancerIPs': '192.168.3.8' } } },
    bedrock+: { metadata+: { annotations+: { 'metallb.io/loadBalancerIPs': '192.168.3.12' } } },
  },

  pod_spec+:: { nodeSelector: { 'kubernetes.io/hostname': 's1-bet1' } },

  // Plugin configuration, mounted as single files so the rest of the plugin directories stay on the volume.
  volumes+:: { 'extra-config': { configMap: { name: 'extra-config' } } },
  minecraft_container+:: {
    volumeMounts+: [
      { name: 'extra-config', mountPath: '/data/plugins/floodgate/config.yml', subPath: 'floodgate.yml' },
      { name: 'extra-config', mountPath: '/data/plugins/BlueMap/core.conf', subPath: 'bluemap.conf' },
    ],
  },

  extraConfig: {
    apiVersion: 'v1',
    kind: 'ConfigMap',
    metadata: { name: 'extra-config', namespace: $._config.namespace },
    data: {
      'floodgate.yml': importstr 'floodgate.yml',
      'bluemap.conf': importstr 'bluemap.conf',
    },
  },
}
