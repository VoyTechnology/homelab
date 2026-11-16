local utils = import 'utils/main.libsonnet';

// Exposed through the Cloudflare Gateway (a tunnel).
{
  // The operator names the Service after the PocketIDInstance.
  route: utils.routes.httpRoute('pocketid', $._config.host, $._config.instanceName, 1411, utils.routes.gateways.external),
}
