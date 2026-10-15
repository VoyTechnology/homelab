local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local util = import '../lib/util.libsonnet';

local host = 'chores.bednarzak.com';
local oidcHost = 'login.bednarzak.com';

local source = helm.new('donetick', values={
  // client_id and client_secret are injected via DT_OAUTH2_* env vars from the operator-created Secret.
  config: { oauth2: {
    name: 'Pocket ID',
    auth_url: 'https://%s/authorize' % oidcHost,
    token_url: 'https://%s/api/oidc/token' % oidcHost,
    user_info_url: 'https://%s/api/oidc/userinfo' % oidcHost,
    redirect_url: 'https://%s/auth/oauth2' % host,
  } },
  ingress: util.ingress('donetick', domain=host, class='external') {
    annotations+: {
      // Do not create the DNS entry as its being managed by the tunnel.
      'dns.kubernetes.io/exclude': 'true',
    }
  }
});
// The operator creates the donetick-oidc-credentials Secret next to this client.
local extraObjects = helm.extraObjects('donetick', overrides={
  donetickOidcClient: {
    apiVersion: 'pocketid.internal/v1alpha1',
    kind: 'PocketIDOIDCClient',
    metadata: {
      name: 'donetick',
      namespace: 'donetick',
      annotations: { 'argocd.argoproj.io/sync-options': 'SkipDryRunOnMissingResource=true' },
    },
    spec: {
      name: 'Donetick',
      callbackUrls: ['https://%s/auth/oauth2' % host],
      launchUrl: 'https://%s' % host,
      allowedUserGroups: [{ name: 'member', namespace: 'pocketid' }],
      secret: { name: 'donetick-oidc-credentials' },
    },
  },
});

appset.new('donetick', 'donetick')
+ appset.addSource(source)
+ appset.addSource(extraObjects)
