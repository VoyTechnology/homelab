local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local util = import '../lib/util.libsonnet';

local source = helm.new('homeassistant', values={
  homeassistant: {
    ingress: util.ingress('homeassistant') {
      className: 'internal-shared', # should be ingressClassName
      hosts: [{
        host: 'homeassistant.{{ .domain }}',
        paths: [{
          path: '/',
          pathType: 'ImplementationSpecific',
        }],
      }], # The chart is stupid and does it wrong
    },
  },
});

appset.new('homeassistant', 'homeassistant')
+ appset.addSource(source)
