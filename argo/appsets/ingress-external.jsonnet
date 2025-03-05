local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';

local source = helm.new('ingress-external');

appset.new('ingress-external', 'ingress-external')
+ appset.addSource(source)
