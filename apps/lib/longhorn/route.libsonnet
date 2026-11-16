local utils = import 'utils/main.libsonnet';

// The UI is served from the internal gateway (LAN only), behind Pocket ID (see auth.libsonnet).
{
  route: utils.routes.httpRoute(
    'longhorn',
    $._config.host,
    'longhorn-frontend',
    80,
    utils.routes.gateways.internal,
  ),
}
