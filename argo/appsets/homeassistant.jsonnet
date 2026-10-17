local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local tanka = import '../lib/tanka.libsonnet';
local util = import '../lib/util.libsonnet';

// Home Assistant itself (StatefulSet, Service, Ingress, ServiceMonitor, the USB device
// mounts) is rendered by Tanka, see argo/apps/homeassistant/homeassistant.libsonnet.
// This chart only carries Matter Server and Matter Hub.
local source = helm.new(
  'homeassistant', values={
    matterhub: {
      ingress: util.ingress('matter', class='internal'),
      # TODO: Make this dynamic per cluster
      nodeSelector: {'kubernetes.io/hostname': 's1-bet1'},
    }
  },
);

local extraObjects = helm.extraObjects('homeassistant');

local tankaSource = tanka.new(
  'ha-jsonnet',
  path='argo/apps/homeassistant',
  namespace='homeassistant',
  // A string is passed through verbatim as Jsonnet source (std.toString of an object would
  // drop hidden fields and the `+` of `_config+::`, so the override would replace _config).
  overrides="{ _config+:: { domain: '{{ .domain }}' } }",
);

appset.new('homeassistant', 'homeassistant')
+ appset.addSource(source)
+ appset.addSource(extraObjects)
+ appset.addSource(tankaSource)
