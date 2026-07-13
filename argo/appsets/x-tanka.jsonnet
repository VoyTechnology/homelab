local appset = import '../lib/appset.libsonnet';
local tanka = import '../lib/tanka.libsonnet';

local source = tanka.new(
  'x-tanka',
  // renovate: datasource=git depName=voytechnology/homelab
  targetRevision='main',
  data={
    _config: {
      // testing port override 
      port: 3001,
    },
  }
);

appset.new('x-tanka', 'x-tanka')
+ appset.addSource(source)
