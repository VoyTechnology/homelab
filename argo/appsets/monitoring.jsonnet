local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';

local source = helm.new('monitoring', values={
  grafana: {
    ingress: {
      hosts: ['grafana.{{ .domain }}'],
      tls: [{
        secretName: 'grafana-tls', hosts: ['grafana.{{ .domain }}']
      }],
    },
    'grafana.ini': {
      server: {
        domain: 'grafana.{{ .domain }}',
        root_url: 'https://grafana.{{ .domain }}',
      },
      'auth.generic_oauth': {
        enabled: false,
        auth_url: 'https://login.{{ .domain }}/auth',
        token_url: 'https://login.{{ .domain }}/token',
        api_url: 'https://login.{{ .domain }}/userinfo',
      },
    },
  },
  mimir: {
    ingress: {
      hosts: ['metrics.{{ .domain }}'],
      tls: [{
        secretName: 'mimir-tls', hosts: ['metrics.{{ .domain }}']
      }],
    },
  },
});

appset.new('monitoring', 'monitoring')
+ appset.addSource(source)

