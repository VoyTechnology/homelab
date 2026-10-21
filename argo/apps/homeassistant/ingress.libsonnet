// Home Assistant's Ingress. The home-libsonnet library deliberately creates none.
{
    haIngress: {
        apiVersion: 'networking.k8s.io/v1',
        kind: 'Ingress',
        metadata: {
            name: 'homeassistant',
            labels: {
                'app.kubernetes.io/name': 'homeassistant',
                'app.kubernetes.io/instance': 'homeassistant',
                'app.kubernetes.io/managed-by': 'Tanka',
            },
            annotations: {
                'cert-manager.io/cluster-issuer': 'letsencrypt',
                // Do not create the DNS entry as its being managed by the tunnel.
                'dns.kubernetes.io/exclude': 'true',
            },
        },
        spec: {
            ingressClassName: $._config.ingressClass,
            tls: [{ hosts: [$._config.domain], secretName: 'homeassistant-tls' }],
            rules: [{
                host: $._config.domain,
                http: { paths: [{
                    path: '/',
                    pathType: 'ImplementationSpecific',
                    backend: { service: { name: 'homeassistant', port: { number: $._config.port } } },
                }] },
            }],
        },
    },
}
