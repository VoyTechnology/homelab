// Pinned here, not in the libraries, so Renovate can bump them.
{
  _images+:: {
    // Mimir's image comes from the vendored jsonnet library, which is wired for that version
    // (the image alone is not safe to bump, 3.2.x needs the query-frontend in the querier ring).
    // Not tracked by Renovate; to override, uncomment and bump by hand.
    // mimir: 'grafana/mimir:3.2.6',
    // renovate: datasource=docker depName=memcached
    memcached: 'memcached:1.6.42-alpine@sha256:43a2e7f74aebfff0c9921f4d367299ced9eacaeaccdc8bb4bc122a4fba2cd909',
    // renovate: datasource=docker depName=prom/memcached-exporter
    memcachedExporter: 'prom/memcached-exporter:v0.16.0@sha256:fa03aba2f2aa6f572bf56ba07dd2960c62433805427be0fddc8b21b8074c1728',
  },
}
