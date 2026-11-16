// Home Assistant itself, with the ha-data repository imported as a mixin (automations, scripts, scenes,
// dashboards and helpers).
local home = import 'github.com/VoyTechnology/ha-data/mixin.libsonnet';
local ha = import 'github.com/VoyTechnology/home-libsonnet/homeassistant/main.libsonnet';

// The helpers are hidden fields of the mixin (the library has no kind for them), and
// are loaded through the `template:` and `utility_meter:` sections of configuration.yaml.
local hidden(o) = [o[n] for n in std.objectFieldsAll(o)];

{
  homeassistant+:
    ha.addMixins({ home: home })
    + {
      _config+:: {
        // Rendered to /config/configuration.yaml; the library adds the sections that load
        // the mixin automations, scripts, scenes and dashboards.
        configuration: {
          // Loads default set of integrations. Do not remove.
          default_config: {},
          prometheus: {},
          http: {
            use_x_forwarded_for: true,
            // The Cloudflare tunnel connector reaches Home Assistant from its node's Tailscale
            // address, so trust the whole Tailscale range to cover node moves and new nodes.
            trusted_proxies: ['10.0.0.0/8', '100.64.0.0/10'],
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
    },
}
