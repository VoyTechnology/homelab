// Pinned here, not in the library, so Renovate can bump them.
{
  _images+:: {
    // renovate: datasource=docker depName=ghcr.io/paperless-ngx/paperless-ngx
    paperless: 'ghcr.io/paperless-ngx/paperless-ngx:3.3.1',
    // renovate: datasource=docker depName=docker.io/library/redis
    redis: 'docker.io/library/redis:8.2-alpine',
  },
}
