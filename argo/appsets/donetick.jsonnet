local appset = import '../lib/appset.libsonnet';
local tanka = import '../lib/tanka.libsonnet';

local namespace = 'donetick';

local source = tanka.new(
  'donetick',
  namespace=namespace,
  overrides={
    _namespace:: namespace,
    _host:: 'chores.bednarzak.com',
  },
);

appset.new('donetick', namespace)
+ appset.addSource(source)
