// Pinned here, not in the libraries, so Renovate can bump them. Keep the CRDs of the libraries in step.
{
  _images+:: {
    // renovate: datasource=docker depName=docker.io/envoyproxy/gateway
    gateway: 'docker.io/envoyproxy/gateway:v1.7.0',
    // renovate: datasource=docker depName=docker.io/envoyproxy/ratelimit
    ratelimit: 'docker.io/envoyproxy/ratelimit:3fb70258',
    // The controller image also runs the tunnels (--tunnel-image).
    // renovate: datasource=docker depName=ghcr.io/matheuscscp/cloudflare-gateway-controller
    controller: 'ghcr.io/matheuscscp/cloudflare-gateway-controller:v0.16.0',
  },
}
