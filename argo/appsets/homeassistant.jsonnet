local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local util = import '../lib/util.libsonnet';

local source = helm.new(
  'homeassistant', values={
    homeassistant: {
      ingress: util.ingress('homeassistant', class='external') {
        // The chart is stupid and does it wrong
        className: 'external',  // should be ingressClassName
        hosts: [{
          host: '{{ .domain }}',
          paths: [{
            path: '/',
            pathType: 'Prefix',
          }],
          tls: [{
            secretName: 'homeassistant-tls',
            hosts: ['{{ .domain }}'],
          }],
        }],
        annotations+: {
          // Do not create the DNS entry as its being managed by the tunnel.
          'dns.kubernetes.io/exclude': 'true',
        },
      },
    },
    musicassistant: {
      ingress: { main:
        util.ingress('musicassistant', class='internal-shared') {
          hosts: [{
            host: 'musicassistant.{{ .domain }}',
            paths: [{ path: '/', pathType: 'Prefix' }],
          }],
        } },
    },
  },
);

appset.new('homeassistant', 'homeassistant')
+ appset.addSource(source)
