// Pinned here, not in the libraries, so Renovate can bump them.
{
  _images+:: {
    // renovate: datasource=docker depName=grafana/mimir
    mimir: 'grafana/mimir:3.1.4',
    // renovate: datasource=docker depName=memcached
    memcached: 'memcached:1.6.42-alpine@sha256:43a2e7f74aebfff0c9921f4d367299ced9eacaeaccdc8bb4bc122a4fba2cd909',
    // renovate: datasource=docker depName=prom/memcached-exporter
    memcachedExporter: 'prom/memcached-exporter:v0.16.0@sha256:fa03aba2f2aa6f572bf56ba07dd2960c62433805427be0fddc8b21b8074c1728',
  },
}
