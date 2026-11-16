local utils = import 'utils/main.libsonnet';

{
  // Django's secret key, shared by every pod. Changing it logs everyone out, so it comes from the store.
  secretKey: utils.secrets.fromShared($._config.namespace, $._config.secretKeyName, {
    [$._config.secretKeyKey]: 'paperless_secret_key',
  }),
}
