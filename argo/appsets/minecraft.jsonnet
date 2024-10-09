local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';

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
  ingress: {
    enabled: true,
    ingressClassName: 'external',
    hosts: [{
      name: 'skynet-map.{{ .domain }}',
      path: '/',
    }],
    tls: [{
      secretName: 'skynet-map-{{ .domain }}',
      hosts: ['skynet-map.{{ .domain }}'],
    }],
  }
};

local source = helm.new(
  'minecraft', values={
    minecraft: {
      minecraftServer: {
        motd: 'Welcome to Skynet 3!',
        extraPorts: [
          bedrockPort,
          mapPort,
        ]
      },
      nodeSelector: {
        'kubernetes.io/hostname': 's1-dub1',
      },
    },
  }
);

appset.new('minecraft', 'minecraft')
+ appset.addSource(source)
