// The Pocket ID client. The operator creates the Secret `oidcSecretName` next to it.
// No generated library for the CRDs, so a plain object.
{
  oidcClient: {
    apiVersion: 'pocketid.internal/v1alpha1',
    kind: 'PocketIDOIDCClient',
    metadata: { name: 'paperless', namespace: $._config.namespace },
    spec: {
      name: 'Paperless',
      isPublic: true,
      pkceEnabled: true,
      callbackUrls: [
        '%s/accounts/oidc/pocketid/login/callback/' % $._config.url,
        // Paperless mobile apps return to this custom scheme after login.
        'x-paperless://oidc-callback',
      ],
      launchUrl: $._config.url,
      allowedUserGroups: [{ name: 'member', namespace: $._config.pocketidNamespace }],
      secret: { name: $._config.oidcSecretName },
    },
  },
}
