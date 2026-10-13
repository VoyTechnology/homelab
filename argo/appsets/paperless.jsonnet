local appset = import '../lib/appset.libsonnet';
local tanka = import '../lib/tanka.libsonnet';

local namespace = 'paperless';

local source = tanka.new(
  'paperless',
  namespace=namespace,
  overrides={
    _namespace:: namespace,
    _host:: 'docs.bednarzak.com',
  },
);

appset.new('paperless', namespace)
+ appset.addSource(source)
