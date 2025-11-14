local appset = '../lib/appset.libsonnet';
local helm = '../lib/helm.libsonnet';
local util = '../lib/util.libsonnet';

local source = helm.new(
    name='metallb',
    repoURL='https://metallb.github.io/metallb',
    chart='metallb',
    targetRevision='v0.15.2',
);

local appset = appset.new('metallb', 'metallb-system')
+ appset.addSource(source)
