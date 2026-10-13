local appset = import '../lib/appset.libsonnet';
local tanka = import '../lib/tanka.libsonnet';

local namespace = 'pocketid';

local source = tanka.new(
  'pocketid',
  namespace=namespace,
  overrides={
    _namespace:: namespace,
    _host:: 'login.bednarzak.com',
  },
);

appset.new('pocketid', namespace)
+ appset.addSource(source)
+ {
  spec+: { template+: { spec+: { syncPolicy+: {
    syncOptions+: [
      // The operator CRDs are large; avoid the client-side apply annotation limit.
      'ServerSideApply=true',
    ],
  } } } },
}
