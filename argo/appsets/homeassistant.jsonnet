local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local util = import '../lib/util.libsonnet';

local source = helm.new('homeassistant', values={
  homeassistant: {
    ingress: util.ingress('homeassistant', class='external') {
      # The chart is stupid and does it wrong
      className: 'external', # should be ingressClassName
      hosts: [{
        host: 'homeassistant.{{ .domain }}',
        paths: [{
          path: '/',
          pathType: 'Prefix',
        }],
      }],
      annotations+: {
        # Do not create the DNS entry as its being managed by the tunnel.
        'dns.kubernetes.io/exclude': 'true',
      },
    },
  },
});

appset.new('homeassistant', 'homeassistant')
+ appset.addSource(source)
