// Pinned here, not in the library, so Renovate can bump them. Keep the CRDs of the library in step.
{
  _images+:: {
    // renovate: datasource=docker depName=quay.io/jetstack/cert-manager-controller
    controller: 'quay.io/jetstack/cert-manager-controller:v1.19.1',
    // renovate: datasource=docker depName=quay.io/jetstack/cert-manager-cainjector
    cainjector: 'quay.io/jetstack/cert-manager-cainjector:v1.19.1',
    // renovate: datasource=docker depName=quay.io/jetstack/cert-manager-webhook
    webhook: 'quay.io/jetstack/cert-manager-webhook:v1.19.1',
    // renovate: datasource=docker depName=quay.io/jetstack/cert-manager-acmesolver
    acmesolver: 'quay.io/jetstack/cert-manager-acmesolver:v1.19.1',
  },
}
