local utils = import 'utils/main.libsonnet';

// Secrets fanned out from the `cluster-secrets` store.
{
  // Cloudflare token for the DNS01 solver.
  cloudflareSecret: utils.secrets.fromShared('cloudflare-secret', {
    token: $._config.cloudflareTokenProperty,
  }),
}
