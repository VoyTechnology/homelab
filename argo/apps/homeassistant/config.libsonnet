// Settings of this deployment on top of the home-libsonnet homeassistant defaults.
{
    _config+:: {
        threadDongle: error 'threadDongle must be set in the config',
        networkInterface: error 'networkInterface must be set in the config',
        nodeName: error 'nodeName must be set in the config',
        domain: error 'domain must be set in the config',
        ingressClass: 'external',
        restPort: 8081,
        webPort: 8082,

        dataStorageSize: '1Gi',
        dataStorageClass: null,

        // The ServiceMonitor scrapes /api/prometheus with this token (the same
        // long-lived access token Matter Hub uses, see extra.values.yaml).
        metricsEnabled: true,
        metricsTokenSecret: { name: 'homeassistant-matterhub', key: 'token' },
    },
}
