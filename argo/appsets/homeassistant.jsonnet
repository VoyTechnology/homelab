local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';

local source = helm.new('homeassistant', values={
  homeassistant: {
    ingress: {
      hosts: [{host: 'homeassistant.{{ .domain }}'}],
      tls: {
        hosts: ['homeassistant.{{ .domain }}'],
      }
    },
  },
});

appset.new('homeassistant', 'homeassistant')
+ appset.addSource(source)
