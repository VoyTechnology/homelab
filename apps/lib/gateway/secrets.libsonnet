local utils = import 'utils/main.libsonnet';

// Secrets fanned out from the `cluster-secrets` store.
{
  // Credentials the GatewayClass points at, under the keys the controller expects.
  cloudflareSecret: utils.secrets.fromShared($._config.namespace, 'cloudflare-gateway-credentials', {
    CLOUDFLARE_API_TOKEN: $._config.apiTokenProperty,
    CLOUDFLARE_ACCOUNT_ID: $._config.accountIdProperty,
  }),
}
