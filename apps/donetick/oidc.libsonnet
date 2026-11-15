// The Pocket ID client. The operator creates the Secret `oidcSecretName` next to it.
// No generated library for the CRDs, so a plain object.
{
  oidcClient: {
    apiVersion: 'pocketid.internal/v1alpha1',
    kind: 'PocketIDOIDCClient',
    metadata: { name: 'donetick', namespace: $._config.namespace },
    spec: {
      name: 'Donetick',
      callbackUrls: [
        $.donetick_config.oauth2.redirect_url,
        // The Donetick mobile app returns to this custom scheme after login.
        'donetick://auth/oauth2',
      ],
      launchUrl: 'https://%s' % $._config.host,
      allowedUserGroups: [{ name: 'member', namespace: $._config.pocketidNamespace }],
      secret: { name: $._config.oidcSecretName },
    },
  },
}
