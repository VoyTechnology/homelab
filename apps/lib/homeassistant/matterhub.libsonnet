// Matter Hub, which exposes Home Assistant entities as Matter devices. The library defaults apply,
// except that the UI is reached through the gateway on a public name, which HAMH only answers
// (instead of a 403) when that host is allow-listed.
{
  matterhub+: {
    matterhub_env+:: {
      HAMH_HTTP_ALLOWED_HOSTS: $._config.matterHost,
    },
  },
}
