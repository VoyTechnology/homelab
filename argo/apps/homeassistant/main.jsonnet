local ha = import 'github.com/VoyTechnology/home-libsonnet/homeassistant/main.libsonnet';
local home = import 'github.com/VoyTechnology/ha-data/mixin.libsonnet';
local config = import 'config.libsonnet';
local images = import 'images.libsonnet';
local ingress = import 'ingress.libsonnet';
local otbr = import 'otbr.libsonnet';

local threadDongle = '/dev/serial/by-id/usb-Nabu_Casa_ZBT-2_14C19FC4DBA8-if00';

// The helpers are hidden fields of the mixin (the library has no kind for them), and
// are loaded through the `template:` and `utility_meter:` sections of configuration.yaml.
local hidden(o) = [o[n] for n in std.objectFieldsAll(o)];

ha + config + images + ingress + otbr {
  // TODO: Pass this through overrides once I figure out how...
  _config+:: {
    threadDongle: threadDongle,
    networkInterface: 'enp6s0',
    nodeName: 's1-bet1',
    devices: {
      'zigbee-dongle': '/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_48595f40c274ef1196c7cd8c8fcc3fa0-if00-port0',
      'thread-dongle': threadDongle,
    },

    // Rendered to /config/configuration.yaml; the library adds the sections that load
    // the mixin automations, scripts, scenes and dashboards.
    configuration: {
      // Loads default set of integrations. Do not remove.
      default_config: {},
      prometheus: {},
      http: {
        use_x_forwarded_for: true,
        trusted_proxies: ['10.0.0.0/8'],
      },
      frontend: { themes: ha.includeDir('merge_named', 'themes') },
      template: std.flattenArrays(hidden(home.haTemplates)),
      utility_meter: std.foldl(function(acc, m) acc + m, hidden(home.haUtilityMeters), {}),
      zha: {
        enable_quirks: true,
        custom_quirks_path: '/config/custom_zha_quirks',
        zigpy_config: {
          ota: {
            otau_directory: '/config/zigpy_ota',
            ikea_provider: true,
            sonoff_provider: true,
          },
        },
      },
    },
  },
}
+ ha.addMixins(home)
