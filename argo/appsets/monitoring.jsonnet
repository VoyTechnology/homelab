local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local util = import '../lib/util.libsonnet';

local source = helm.new('monitoring', values={
  cluster_name: '{{ .cluster }}',
  domain: '{{ .domain }}',
  grafana: {
    ingress: util.ingress('grafana'),
    'grafana.ini': {
      server: {
        domain: 'grafana.{{ .domain }}',
        root_url: 'https://grafana.{{ .domain }}',
      },
      'auth.generic_oauth': {
        auth_url: 'https://login.{{ .domain }}/auth',
        token_url: 'https://login.{{ .domain }}/token',
        api_url: 'https://login.{{ .domain }}/userinfo',
      },
    },
  },
  mimir: {
    ingress: util.ingress('metrics'),
  },
  oncall: {
    base_url: 'oncall.{{ .domain }}',
    externalGrafana: { url: 'https://grafana.{{ .domain }}' },
  },
});

appset.new('monitoring', 'monitoring')
+ appset.addSource(source)
