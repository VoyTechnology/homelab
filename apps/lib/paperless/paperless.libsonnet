// Paperless settings on top of the library: sign-in through Pocket ID only.
{
  // Accounts are created on first SSO login, groups are not synced. The mobile app runs the token
  // exchange itself without a secret, so the client is public and the server uses PKCE as well.
  oidcProviders:: {
    openid_connect: {
      APPS: [{
        provider_id: 'pocketid',
        name: 'Pocket ID',
        client_id: '$(OIDC_CLIENT_ID)',
        secret: '',
        settings: {
          server_url: 'https://%s/.well-known/openid-configuration' % $._config.oidcHost,
          oauth_pkce_enabled: true,
        },
      }],
    },
  },

  paperless_env+:: {
    // Traffic arrives through the in-cluster cloudflared pod.
    PAPERLESS_USE_X_FORWARD_HOST: true,
    PAPERLESS_USE_X_FORWARD_PORT: true,
    PAPERLESS_ACCOUNT_ALLOW_SIGNUPS: false,
    PAPERLESS_SOCIALACCOUNT_ALLOW_SIGNUPS: true,
    PAPERLESS_SOCIAL_AUTO_SIGNUP: true,
    PAPERLESS_APPS: 'allauth.socialaccount.providers.openid_connect',
    OIDC_CLIENT_ID: { secretKeyRef: { name: $._config.oidcSecretName, key: 'client_id' } },
    // Kubernetes expands $(OIDC_CLIENT_ID) only from variables listed before this one; the library
    // sorts the variables by name and OIDC_ comes before PAPERLESS_.
    PAPERLESS_SOCIALACCOUNT_PROVIDERS: std.toString($.oidcProviders),
  },

  // Django rejects the pod IP as a Host, so the probe sends the public host.
  paperless_container+:: {
    readinessProbe+: {
      httpGet+: { httpHeaders: [{ name: 'Host', value: $._config.host }] },
    },
  },
}
