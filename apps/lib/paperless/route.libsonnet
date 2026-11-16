local utils = import 'utils/main.libsonnet';

// Exposed through the Cloudflare Gateway (a tunnel).
{
  route: utils.routes.httpRoute('paperless', $._config.host, $.paperlessService.metadata.name, $.port, utils.routes.gateways.external),
}
