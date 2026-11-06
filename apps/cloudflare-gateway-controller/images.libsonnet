// Pinned here, not in the library, so Renovate can bump it. Keep the CRDs of the library in step.
{
  _images+:: {
    // renovate: datasource=docker depName=ghcr.io/matheuscscp/cloudflare-gateway-controller
    controller: 'ghcr.io/matheuscscp/cloudflare-gateway-controller:v0.16.0',
  },
}
