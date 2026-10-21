{
    _config:: {
        threadDongle: error "threadDongle must be set in the config",
        networkInterface: error 'networkInterface must be set in the config',
        nodeName: error 'nodeName must be set in the config',
        // Host devices passed through to Home Assistant, any number of them:
        // volume/mount name -> path on the node (also the path inside the container).
        devices: {},
        domain: error 'domain must be set in the config',
        restPort: 8081,
        webPort: 8082,

        dataStorageSize: '1Gi',
        dataStorageClass: null,

        homeassistant: {
            port: 8123,
            ingressClass: 'external',
            // Size of the /config volume. This is the volumeClaimTemplate of the
            // StatefulSet, which is immutable: changing it needs a manual PVC resize.
            storageSize: '5Gi',
            // The home-assistant ServiceMonitor scrapes /api/prometheus with this token
            // (same long-lived access token Matter Hub uses, see extra.values.yaml).
            metricsTokenSecret: { name: 'homeassistant-matterhub', key: 'token' },
            metricsInterval: '30s',

            // Pull-based config deploy from the ha-data `generated` branch. Off by default:
            // the sidecars share the pod with HA, so enable only once the
            // `ha_data_github_token` property exists in shared-secrets.
            configSync: {
                enabled: false,
                repo: 'https://github.com/VoyTechnology/ha-data',
                ref: 'generated',
                period: '30s',
                tokenProperty: 'ha_data_github_token',
            },
        },
    }
}
