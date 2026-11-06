// Cloudflare is the DNS provider (the library's default); the API token comes from the
// `cloudflare-secret` Secret in this namespace.
{
  external_dns_container+:: {
    args+: ['--annotation-filter=dns.kubernetes.io/exclude notin (true)'],
    env+: [
      { name: 'CF_API_TOKEN', valueFrom: { secretKeyRef: { name: 'cloudflare-secret', key: 'token' } } },
    ],
  },
}
