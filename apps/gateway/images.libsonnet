// Pinned here, not in the libraries, so Renovate can bump them. Keep the CRDs of the libraries in step.
// main.libsonnet maps these onto the keys the libraries read.
{
  _images+:: {
    // renovate: datasource=docker depName=docker.io/envoyproxy/gateway
    envoyGateway: 'docker.io/envoyproxy/gateway:v1.7.0',
    // renovate: datasource=docker depName=docker.io/envoyproxy/ratelimit
    envoyRatelimit: 'docker.io/envoyproxy/ratelimit:3fb70258',
    // The controller image also runs the tunnels (--tunnel-image).
    // renovate: datasource=docker depName=ghcr.io/matheuscscp/cloudflare-gateway-controller
    cloudflareGateway: 'ghcr.io/matheuscscp/cloudflare-gateway-controller:v0.16.0',
  },
}
