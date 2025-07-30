local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local util = import '../lib/util.libsonnet';

local source = helm.new(
  'longhorn', values={
    longhorn: {
      ingress: util.ingress('longhorn', class='internal-login') {
        secureBackends: true,
        host: 'longhorn.{{ .domain }}',
        tls: true,
        tlsSecret: 'longhorn-tls',
      },
    },
  },
);

appset.new('longhorn', 'longhorn-system')
+ appset.addSource(source)
