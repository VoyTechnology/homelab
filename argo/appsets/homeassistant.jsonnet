local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';

local source = helm.new('homeassistant', values={
  homeassistant: {
    ingress: {
      hosts: [{
        host:'homeassistant.{{ .domain }}'
        paths: [{
          path: '/'
          pathType: 'ImplementationSpecific'
        }],
      }], # The chart is stupid and does it wrong
      tls: [], # temporary until we can figure it out
    },
  },
});

appset.new('homeassistant', 'homeassistant')
+ appset.addSource(source)
