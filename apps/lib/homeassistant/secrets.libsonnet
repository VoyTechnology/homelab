local utils = import 'utils/main.libsonnet';

{
  // The long-lived access token and public URL of Home Assistant. The token is read by Matter Hub, the
  // ServiceMonitor and the reload job; only the token goes through the cluster, the URL is the public one.
  tokenSecret: utils.secrets.fromShared($._config.tokenSecretName, {
    token: 'homeassistant_token',
    url: 'homeassistant_url',
  }),
}
