// Pinned here, not in the library, so Renovate can bump them.
{
  _images+:: {
    // renovate: datasource=docker depName=docker.io/envoyproxy/gateway
    gateway: 'docker.io/envoyproxy/gateway:v1.7.0',
    // renovate: datasource=docker depName=docker.io/envoyproxy/ratelimit
    ratelimit: 'docker.io/envoyproxy/ratelimit:3fb70258',
  },
}
