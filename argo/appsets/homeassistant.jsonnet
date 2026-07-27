local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local tanka = import '../lib/tanka.libsonnet';
local util = import '../lib/util.libsonnet';

// usbDevices is a list of devices that should be mounted into the homeassistant pod. The key is the name of the device, and the value is the path to the device on the host.
local usbDevices = {
  devices:: {
    "zigbee-dongle": "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_48595f40c274ef1196c7cd8c8fcc3fa0-if00-port0",
    "thread-dongle": "/dev/serial/by-id/usb-Nabu_Casa_ZBT-2_14C19FC4DBA8-if00",
  },

  additionalVolumes:: [{
      name: device.key,
      hostPath: {
        path: device.value,
      }
  } for device in std.objectKeysValues(super.devices) ],

  additionalMounts:: [{
      name: device.key,
      mountPath: device.value,
  } for device in std.objectKeysValues(super.devices) ],
};

local source = helm.new(
  'homeassistant', values={
    homeassistant: {
      additionalVolumes: usbDevices.additionalVolumes,
      additionalMounts: usbDevices.additionalMounts,
      nodeSelector: {
        # TODO: Make this dynamic per cluster
        'kubernetes.io/hostname': 's1-bet1',
      },
      # The chart does not follow the standards. 
      ingress: {
        enabled: true,
        className: 'external',  // should be ingressClassName
        annotations+: {
          // Do not create the DNS entry as its being managed by the tunnel.
          'dns.kubernetes.io/exclude': 'true',
        },
        hosts: [{
          host: '{{ .domain }}',
          paths: [{
            path: '/',
            pathType: 'ImplementationSpecific',
          }],
        }],
        tls: [{
          secretName: 'homeassistant-tls',
          hosts: ['{{ .domain }}'],
        }],
      },
    },
    matterhub: {
      ingress: util.ingress('matter', class='internal'),
      # TODO: Make this dynamic per cluster
      nodeSelector: {'kubernetes.io/hostname': 's1-bet1'},
    }
  },
);

local extraObjects = helm.extraObjects('homeassistant');

local otbr = tanka.new(
  'ha-jsonnet',
  path='argo/apps/homeassistant',
  namespace='homeassistant',
  overrides={
    _namespace:: 'homeassistant',
    _cluster:: '{{ .cluster }}',
    _config+:: {
      threadDongle: usbDevices.devices['thread-dongle'],
      backboneIf: 'enp6s0',
      nodeName: 's1-bet1',
    }
  },
);

appset.new('homeassistant', 'homeassistant')
+ appset.addSource(source)
+ appset.addSource(extraObjects)
+ appset.addSource(otbr)
