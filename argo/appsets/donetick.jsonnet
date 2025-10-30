local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local util = import '../lib/util.libsonnet';

local source = helm.new('donetick', values={
  ingress: util.ingress('donetick', domain='chores.bednarzak.com', class='external') {
    annotations+: {
      // Do not create the DNS entry as its being managed by the tunnel.
      'dns.kubernetes.io/exclude': 'true',
    }
  }
});
local extraObjects = helm.extraObjects('donetick');

appset.new('donetick', 'donetick')
+ appset.addSource(source)
+ appset.addSource(extraObjects)
+ appset.addIgnoreDifferences([{
    group: '',
    kind: 'Secret',
    name: 'donetick-secrets',
    jsonPointers: ['/data/DT_JWT_SECRET']
  }])
