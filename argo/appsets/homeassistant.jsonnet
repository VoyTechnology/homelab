local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local util = import '../lib/util.libsonnet';

local source = helm.new('homeassistant', values={
  homeassistant: {
    ingress: util.ingress('homeassistant', class='external') {
      className: 'external', # should be ingressClassName
      hosts: [{
        host: 'homeassistant.{{ .domain }}',
        paths: [{
          path: '/',
          pathType: 'Prefix',
        }],
      }], # The chart is stupid and does it wrong
    },
  },
});

appset.new('homeassistant', 'homeassistant')
+ appset.addSource(source)
