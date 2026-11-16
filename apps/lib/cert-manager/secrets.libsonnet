local home = import 'home/main.libsonnet';

// Secrets fanned out from the `cluster-secrets` store.
{
  // Cloudflare token for the DNS01 solver.
  cloudflareSecret: home.secrets.fromShared($._config.namespace, 'cloudflare-secret', {
    token: $._config.cloudflareTokenProperty,
  }),
}
