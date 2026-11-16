// Pinned here, not in the libraries, so Renovate can bump them.
{
  homeassistant+: {
    _images+:: {
      // renovate: datasource=docker depName=ghcr.io/home-assistant/home-assistant
      homeassistant: 'ghcr.io/home-assistant/home-assistant:2026.10.2',
    },
  },
  otbr+: {
    _images+:: {
      // renovate: datasource=docker depName=ghcr.io/ownbee/hass-otbr-docker
      otbr: 'ghcr.io/ownbee/hass-otbr-docker:latest',
    },
  },
  matterServer+: {
    _images+:: {
      // renovate: datasource=docker depName=ghcr.io/matter-js/matterjs-server
      matterServer: 'ghcr.io/matter-js/matterjs-server:1.5.5',
      // renovate: datasource=docker depName=docker.io/library/busybox
      busybox: 'docker.io/library/busybox:1.38.0',
    },
  },
  matterhub+: {
    _images+:: {
      // renovate: datasource=docker depName=ghcr.io/riddix/home-assistant-matter-hub
      matterhub: 'ghcr.io/riddix/home-assistant-matter-hub:2.0.48',
    },
  },
  _images+:: {
    // renovate: datasource=docker depName=curlimages/curl
    curl: 'curlimages/curl:8.23.0',
  },
}
