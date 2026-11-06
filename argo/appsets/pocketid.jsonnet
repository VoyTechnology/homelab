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
  // Deleting the appset must leave the instance and its PVC alone (it moves to Flux).
  spec+: { syncPolicy+: { preserveResourcesOnDeletion: true } },
}
+ {
  spec+: { template+: { spec+: { syncPolicy+: {
    syncOptions+: [
      // The operator CRDs are large; avoid the client-side apply annotation limit.
      'ServerSideApply=true',
    ],
  } } } },
}
