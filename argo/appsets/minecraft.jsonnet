local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';

local source = helm.new(
  'minecraft', values={
    minecraftServer: {
      motd: 'Welcome to Skynet 3!',
    },
    nodeSelector: {
      name: 's1-dub1',
    },
  }
);

appset.new('minecraft', 'minecraft')
+ appset.addSource(source)
