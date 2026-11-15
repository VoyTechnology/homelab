// Matter Hub's web UI on the internal ingress, with a certificate from cert-manager.
{
  matterhubIngress: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'Ingress',
    metadata: {
      name: $.matterhub.matterhubService.metadata.name,
      namespace: $._config.namespace,
      labels: $.matterhub.matterhubService.metadata.labels,
      annotations: { 'cert-manager.io/cluster-issuer': 'letsencrypt' },
    },
    spec: {
      ingressClassName: 'traefik',
      tls: [{ secretName: 'matter-tls', hosts: [$._config.matterHost] }],
      rules: [{
        host: $._config.matterHost,
        http: { paths: [{
          path: '/',
          pathType: 'Prefix',
          backend: { service: {
            name: $.matterhub.matterhubService.metadata.name,
            port: { number: $.matterhub._config.port },
          } },
        }] },
      }],
    },
  },
}
