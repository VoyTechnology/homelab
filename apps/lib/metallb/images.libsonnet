// Pinned here, not in the library, so Renovate can bump them.
{
  _images+:: {
    // renovate: datasource=docker depName=quay.io/metallb/controller
    controller: 'quay.io/metallb/controller:v0.15.2',
    // renovate: datasource=docker depName=quay.io/metallb/speaker
    speaker: 'quay.io/metallb/speaker:v0.15.2',
    // renovate: datasource=docker depName=quay.io/frrouting/frr
    frr: 'quay.io/frrouting/frr:9.1.3',
  },
}
