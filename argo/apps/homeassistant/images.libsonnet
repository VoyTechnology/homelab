// The Home Assistant image is pinned by the home-libsonnet library.
{
    _images+:: {
        // renovate: datasource=docker depName=ghcr.io/ownbee/hass-otbr-docker
        otbr: 'ghcr.io/ownbee/hass-otbr-docker:latest',
        // renovate: datasource=docker depName=curlimages/curl
        curl: 'curlimages/curl:8.23.0',
    },
}
