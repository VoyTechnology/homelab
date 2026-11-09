// Home Assistant's route. The home-libsonnet library deliberately creates none.
// Exposed through the external-cloudflare Gateway; DNS is managed by the gateway controller.
{
    haRoute: {
        apiVersion: 'gateway.networking.k8s.io/v1',
        kind: 'HTTPRoute',
        metadata: {
            name: 'homeassistant',
            labels: {
                'app.kubernetes.io/name': 'homeassistant',
                'app.kubernetes.io/instance': 'homeassistant',
                'app.kubernetes.io/managed-by': 'Tanka',
            },
        },
        spec: {
            parentRefs: [{ name: 'external-cloudflare', namespace: 'gateway-system' }],
            hostnames: [$._config.domain],
            rules: [{ backendRefs: [{ name: 'homeassistant', port: $._config.port }] }],
        },
    },
}
