// Login through Pocket ID, enforced by the gateway. No generated libraries for either CRD, so plain objects.
{
  local pocketid = $._config.pocketid,
  local redirect = 'https://%s/oauth2/callback' % $._config.host,

  // The operator creates the client in Pocket ID and writes its credentials to the Secret below, under
  // the key names Envoy Gateway expects.
  oidcClient: {
    apiVersion: 'pocketid.internal/v1alpha1',
    kind: 'PocketIDOIDCClient',
    metadata: { name: 'longhorn', namespace: $._config.namespace },
    spec: {
      name: 'Longhorn',
      launchUrl: 'https://%s' % $._config.host,
      callbackUrls: [redirect],
      isPublic: false,
      pkceEnabled: true,
      allowedUserGroups: [{ name: $._config.allowedGroup, namespace: 'pocketid' }],
      secret: {
        name: 'longhorn-oidc-credentials',
        keys: { clientID: 'client-id', clientSecret: 'client-secret' },
      },
    },
  },

  authPolicy: {
    apiVersion: 'gateway.envoyproxy.io/v1alpha1',
    kind: 'SecurityPolicy',
    metadata: { name: 'longhorn', namespace: $._config.namespace },
    spec: {
      targetRefs: [{ group: 'gateway.networking.k8s.io', kind: 'HTTPRoute', name: $.route.metadata.name }],
      oidc: {
        provider: {
          issuer: $._config.oidcIssuer,
          // Envoy's upstream TLS stops at 1.2 and Cloudflare in front of Pocket ID requires 1.3, so the
          // token call goes to the Service. Setting both endpoints also skips the issuer discovery.
          authorizationEndpoint: '%s/authorize' % $._config.oidcIssuer,
          tokenEndpoint: 'http://%s.%s.svc.cluster.local:%d/api/oidc/token' % [pocketid.service, pocketid.namespace, pocketid.port],
          backendRefs: [{ name: pocketid.service, namespace: pocketid.namespace, port: pocketid.port }],
        },
        clientIDRef: { name: $.oidcClient.spec.secret.name },
        clientSecret: { name: $.oidcClient.spec.secret.name },
        redirectURL: redirect,
        scopes: ['openid', 'profile', 'email'],
      },
    },
  },
}
