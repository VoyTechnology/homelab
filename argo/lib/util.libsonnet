{
  ingress(name, class='internal'): {
    ingressClassName: class,
    annotations: {
        'cert-manager.io/cluster-issuer': 'letsencrypt',
    },
    hosts: [name+'.{{ .domain}}'],
    tls: [{
      secretName: name + '-tls',
      hosts: [name+'.{{ .domain }}'],
    }],
  }
}
