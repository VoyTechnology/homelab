local utils = import 'utils/main.libsonnet';

// Both routes attach to the internal gateway. The environment moves Home Assistant to the external
// Cloudflare gateway with `route+: { spec+: { parentRefs: [...] } }`.
{
  route: utils.routes.httpRoute(
    'homeassistant',
    $._config.domain,
    $.homeassistant.haService.metadata.name,
    $.homeassistant._config.port,
    utils.routes.gateways.internal,
  ),

  matterhubRoute: utils.routes.httpRoute(
    $.matterhub.matterhubService.metadata.name,
    $._config.matterHost,
    $.matterhub.matterhubService.metadata.name,
    $.matterhub._config.port,
    utils.routes.gateways.internal,
  ),
}
