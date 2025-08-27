local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local util = import '../lib/util.libsonnet';

local source = helm.new(
  'homeassistant', values={
    homeassistant: {
      additionalVolumes: [{
        name: "zigbee-dongle",
        hostPath: {
          # TODO: Make this dynamic per cluster
          path: "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_48595f40c274ef1196c7cd8c8fcc3fa0-if00-port0",
          type: "CharDevice"
        }
      }],
      additionalMounts: [{
        name: "zigbee-dongle",
        mountPath: "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_48595f40c274ef1196c7cd8c8fcc3fa0-if00-port0",
      }],
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
    musicassistant: {
      ingress: { main: util.ingress('music', class='internal-shared') {
        # Override hosts to use the proper path
        hosts: [{
          host: 'music.{{ .domain }}',
          paths: [{
            path: '/',
            pathType: 'ImplementationSpecific',
            service: {
              name: 'homeassistant-musicassistant',
              port: 8095,
            }
          }],
        }],
      } },
    }
  },
);

local extraObjects = helm.extraObjects('homeassistant');

appset.new('homeassistant', 'homeassistant')
+ appset.addSource(source)
+ appset.addSource(extraObjects)
