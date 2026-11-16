local utils = import 'utils/main.libsonnet';

// Grafana is served through the Cloudflare tunnel gateway.
{
  route: utils.routes.httpRoute(
    'grafana',
    $._config.grafanaHost,
    'grafana',
    80,
    utils.routes.gateways.cloudflare,
  ),
}
