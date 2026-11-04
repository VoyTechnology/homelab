local appset = import '../lib/appset.libsonnet';
local tanka = import '../lib/tanka.libsonnet';

// Native Tanka layout (apps/x-tanka/environments/<cluster>); experiment only.
local source = tanka.newNative(
  'x-tanka',
  // renovate: datasource=git depName=voytechnology/homelab
  targetRevision='main',
);

appset.new('x-tanka', 'x-tanka')
+ appset.addSource(source)
