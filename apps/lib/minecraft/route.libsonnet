local utils = import 'utils/main.libsonnet';

// The map is exposed through the Cloudflare Gateway.
{
  route: utils.routes.httpRoute('skynet-map', $._config.mapHost, $._config.name + '-map', $.ports.map.port, utils.routes.gateways.external),
}
