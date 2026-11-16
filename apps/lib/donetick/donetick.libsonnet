// Donetick settings on top of the library: sign-in through Pocket ID.
{
  donetick_config+:: {
    // client_id and client_secret come from DT_OAUTH2_CLIENT_ID / DT_OAUTH2_CLIENT_SECRET.
    oauth2: {
      name: 'Pocket ID',
      auth_url: 'https://%s/authorize' % $._config.oidcHost,
      token_url: 'https://%s/api/oidc/token' % $._config.oidcHost,
      user_info_url: 'https://%s/api/oidc/userinfo' % $._config.oidcHost,
      redirect_url: 'https://%s/auth/oauth2' % $._config.host,
    },
  },

  donetick_env+:: {
    DT_TELEGRAM_TOKEN: { secretKeyRef: { name: $._config.secretName, key: 'DT_TELEGRAM_TOKEN' } },
    DT_OAUTH2_CLIENT_ID: { secretKeyRef: { name: $._config.oidcSecretName, key: 'client_id' } },
    DT_OAUTH2_CLIENT_SECRET: { secretKeyRef: { name: $._config.oidcSecretName, key: 'client_secret' } },
  },
}
