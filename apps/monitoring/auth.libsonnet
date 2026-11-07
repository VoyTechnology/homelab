local k = import 'k.libsonnet';

local container = k.core.v1.container;

// Two logins side by side: Dex (generic OAuth, as before) and Pocket ID. Grafana has a single generic OAuth
// provider, so Pocket ID goes through the Okta one, which is plain OIDC with configurable endpoints.
{
  local issuer = $._config.oidcIssuer,
  local dex = 'https://login.%s' % $._config.domain,
  local host = 'grafana.%s' % $._config.domain,

  // The operator creates the client in Pocket ID and writes its credentials to the Secret below.
  oidcClient: {
    apiVersion: 'pocketid.internal/v1alpha1',
    kind: 'PocketIDOIDCClient',
    metadata: { name: 'grafana', namespace: $._config.namespace },
    spec: {
      name: 'Grafana',
      launchUrl: 'https://%s' % host,
      callbackUrls: ['https://%s/login/okta' % host],
      isPublic: false,
      pkceEnabled: true,
      allowedUserGroups: [{ name: $._config.allowedGroup, namespace: 'pocketid' }],
      secret: {
        name: 'grafana-pocketid',
        keys: { clientID: 'client-id', clientSecret: 'client-secret' },
      },
    },
  },

  grafana+: {
    iniConfig:: {
      sections+: {
        auth+: { disable_login_form: true },
        // The flag above only hides the form, basic auth would still work.
        'auth.basic'+: { enabled: false },
        'auth.generic_oauth'+: {
          enabled: true,
          name: 'Dex',
          scopes: 'openid email profile groups offline_access',
          skip_org_role_sync: true,
          allow_sign_up: false,
          oauth_allow_insecure_email_lookup: true,
          auth_url: '%s/auth' % dex,
          token_url: '%s/token' % dex,
          api_url: '%s/userinfo' % dex,
        },
        'auth.okta'+: {
          enabled: true,
          name: 'Pocket ID',
          scopes: 'openid email profile groups',
          skip_org_role_sync: true,
          allow_sign_up: false,
          oauth_allow_insecure_email_lookup: true,
          use_pkce: true,
          auth_url: '%s/authorize' % issuer,
          token_url: '%s/api/oidc/token' % issuer,
          api_url: '%s/api/oidc/userinfo' % issuer,
        },
      },
    },

    grafana_container+:: container.withEnvMixin([
      { name: 'GF_AUTH_GENERIC_OAUTH_CLIENT_ID', valueFrom: { secretKeyRef: { name: 'grafana-cloud', key: 'oauth-client-id' } } },
      { name: 'GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET', valueFrom: { secretKeyRef: { name: 'grafana-cloud', key: 'oauth-client-secret' } } },
      { name: 'GF_AUTH_OKTA_CLIENT_ID', valueFrom: { secretKeyRef: { name: $.oidcClient.spec.secret.name, key: 'client-id' } } },
      { name: 'GF_AUTH_OKTA_CLIENT_SECRET', valueFrom: { secretKeyRef: { name: $.oidcClient.spec.secret.name, key: 'client-secret' } } },
    ]),
  },
}
