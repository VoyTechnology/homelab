local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local util = import '../lib/util.libsonnet';

// Is this a good idea to specify them here or should we have a more dynamic method of loading them?
local buckets = [

];

local source = helm.new('minio', values={
  minio: {
    consoleIngress: util.ingress('minio', class='internal') {
      enabled: true,
    },
    oidc: {
      configUrl: 'https://login.{{ .domain }}/.well-known/openid-configuration',
      redirectUri: 'https://minio.{{ .domain }}/oauth_callback',
    }
  },
});

appset.new('minio', 'minio')
+ appset.addSource(source)
