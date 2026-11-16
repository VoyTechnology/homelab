local utils = import 'utils/main.libsonnet';

{
  // The JWT signing secret (changing it logs everyone out) and the Telegram bot token.
  secrets: utils.secrets.fromShared($._config.namespace, $._config.secretName, {
    DT_JWT_SECRET: 'donetick_jwt_secret',
    DT_TELEGRAM_TOKEN: 'donetick_telegram_token',
  }),
}
