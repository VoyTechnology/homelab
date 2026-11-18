// The Pocket ID client. The operator creates the Secret `oidcSecretName` next to it; put its
// client-id and client-secret into Seerr's OIDC provider config.
// Seerr (seerr-team/seerr#2715, not yet in a release) redirects back to /login to sign in and to
// the linked-accounts page to link an account, so both must be allowed.
// No generated library for the CRDs, so a plain object.
{
  oidcClient: {
    apiVersion: 'pocketid.internal/v1alpha1',
    kind: 'PocketIDOIDCClient',
    metadata: { name: 'seerr', namespace: $._config.namespace },
    spec: {
      name: 'Seerr',
      launchUrl: $._config.url,
      callbackUrls: [
        '%s/login' % $._config.url,
        '%s/profile/settings/linked-accounts' % $._config.url,
      ],
      isPublic: false,
      pkceEnabled: true,
      // No allowedUserGroups: every Pocket ID user may sign in.
      secret: {
        name: $._config.oidcSecretName,
        keys: { clientID: 'client-id', clientSecret: 'client-secret' },
      },
    },
  },
}
