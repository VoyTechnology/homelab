{
  _config+:: {
    namespace: 'homeassistant',
    // Home Assistant is exposed through the Cloudflare Gateway; Matter Hub's UI on the internal ingress.
    domain: 'bet1.bednarzak.com',
    matterHost: 'matter.' + self.domain,

    // Everything with a radio or a host network interface runs on this node.
    nodeName: 's1-bet1',
    networkInterface: 'enp6s0',
    zigbeeDongle: '/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_48595f40c274ef1196c7cd8c8fcc3fa0-if00-port0',
    threadDongle: '/dev/serial/by-id/usb-Nabu_Casa_ZBT-2_14C19FC4DBA8-if00',

    // Long-lived access token and URL of Home Assistant, shared by Matter Hub, the ServiceMonitor and the reload job.
    tokenSecretName: 'homeassistant-matterhub',
  },

  homeassistant+: {
    _config+:: {
      nodeName: $._config.nodeName,
      devices: {
        'zigbee-dongle': $._config.zigbeeDongle,
        'thread-dongle': $._config.threadDongle,
      },
      // The ServiceMonitor scrapes /api/prometheus with the token.
      metricsEnabled: true,
      metricsTokenSecret: { name: $._config.tokenSecretName, key: 'token' },
    },
  },

  otbr+: {
    _config+:: {
      nodeName: $._config.nodeName,
      threadDongle: $._config.threadDongle,
      networkInterface: $._config.networkInterface,
    },
  },

  matterServer+: {
    _config+:: {
      networkInterface: $._config.networkInterface,
      dataStorageClass: 'longhorn',
    },
  },

  matterhub+: {
    _config+:: {
      nodeName: $._config.nodeName,
      secretName: $._config.tokenSecretName,
      dataStorageClass: 'longhorn',
    },
  },
}
