local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local util = import '../lib/util.libsonnet';

local source = helm.new(
    'adguard', values={
        ingress: util.ingress('adguard'),
    },
);

appset.new('adguard', 'adguard')
+ appset.addSource(source)
