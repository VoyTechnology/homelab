local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local util = import '../lib/util.libsonnet';

local source = helm.new(
  'homeassistant', values={
    homeassistant: {
      # The chart does not follow the standards. 
      ingress: {
        enabled: true,
        className: 'external',  // should be ingressClassName
        annotations+: {
          // Do not create the DNS entry as its being managed by the tunnel.
          'dns.kubernetes.io/exclude': 'true',
        },
        hosts: [{
          host: '{{ .domain }}',
          paths: [{
            path: '/',
            pathType: 'ImplementationSpecific',
          }],
        }],
        tls: [{
          secretName: 'homeassistant-tls',
          hosts: ['{{ .domain }}'],
        }],
        
      },
    },
  },
);

appset.new('homeassistant', 'homeassistant')
+ appset.addSource(source)
