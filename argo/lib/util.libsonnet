{
  ingress(name, class='internal'): {
    ingressClassName: class,
    annotations: {
      'cert-manager.io/cluster-issuer': 'letsencrypt',
    },
    hosts: [name + '.{{ .domain}}'],
    tls: [{
      secretName: name + '-tls',
      hosts: [name + '.{{ .domain }}'],
    }],
  },

  // env converts a name and value into a Kubernetes env object
  env(name, value): {
    name: name,
    value: value,
  },
}
