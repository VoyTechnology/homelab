local utils = import 'utils/main.libsonnet';

// Exposed through the Cloudflare Gateway (a tunnel).
{
  route: utils.routes.httpRoute('donetick', $._config.host, $.donetickService.metadata.name, $.port, utils.routes.gateways.external),
}
