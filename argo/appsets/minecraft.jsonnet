local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';

local domain = 'voy.technology';

local bedrockPort = {
  name: 'bedrock',
  containerPort: 19132,
  protocol: 'UDP',
  service: {
    enabled: true,
    type: 'LoadBalancer',
    port: 19132,
  },
};

local mapPort = {
  name: 'map',
  containerPort: 8100,
  protocol: 'TCP',
  service: {
    enabled: true,
    type: 'ClusterIP',
    port: 8100,
  },
};

local source = helm.new(
  'minecraft',
  repoURL='https://itzg.github.io/minecraft-server-charts/',
  chart='minecraft',
  // renovate: datasource=helm depName=minecraft registryUrl=https://itzg.github.io/minecraft-server-charts/
  targetRevision='5.3.1',
  values={
    minecraftServer: {
      motd: 'Welcome to Skynet 3!',
      extraPorts: [
        bedrockPort,
        mapPort,
      ],
    },
    nodeSelector: {
      'kubernetes.io/hostname': 's1-bet1',
    },
  }
);

// The map is exposed through the external-cloudflare Gateway; the chart cannot render an HTTPRoute.
local extraObjects = helm.extraObjects('minecraft', overrides={
  mapRoute: {
    apiVersion: 'gateway.networking.k8s.io/v1',
    kind: 'HTTPRoute',
    metadata: { name: 'skynet-map', namespace: 'minecraft' },
    spec: {
      parentRefs: [{ name: 'external-cloudflare', namespace: 'gateway-system' }],
      hostnames: ['skynet-map.' + domain],
      rules: [{ backendRefs: [{ name: 'minecraft-map', port: 8100 }] }],
    },
  },
});

appset.new('minecraft', 'minecraft')
+ appset.addSource(source)
+ appset.addSource(extraObjects)
