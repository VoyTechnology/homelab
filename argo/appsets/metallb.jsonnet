local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local util = import '../lib/util.libsonnet';

local source = helm.new('metallb',
    repoURL='https://metallb.github.io/metallb',
    chart='metallb',
    targetRevision='0.15.2',
);

local extraObjects = helm.extraObjects('metallb', overrides={
    homelabIpAddressPool: { spec: {
        addresses: ['{{ index .metadata "homelabIpAddressPool" }}']
    }}
});

appset.new('metallb', 'metallb-system')
+ appset.addSource(source)
+ appset.addSource(extraObjects)
