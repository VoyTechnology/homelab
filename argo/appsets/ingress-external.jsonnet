local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';

local source = helm.new(
  name='ingress-external',
  repoURL='https://helm.strrl.dev',
  chart='cloudflare-tunnel-ingress-controller',
  targetRevision='0.0.9',
);

appset.new('ingress-external', 'ingress-external')
+ appset.addSource(source)
