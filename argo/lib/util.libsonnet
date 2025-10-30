{
  ingress(name, domain=null, class='internal'): {
    domain:: if domain == null then (name + '{{ .domain }}') else domain,
    enabled: true,
    ingressClassName: class,
    annotations: {
      'cert-manager.io/cluster-issuer': 'letsencrypt',
    },
    hosts: [domain],
    tls: [{
      secretName: name + '-tls',
      hosts: [domain],
    }],
  },

  // env converts a name and value into a Kubernetes env object
  env(name, value): {
    name: name,
    value: value,
  },

  secretEnv(name, file, key): {
    name: name,
    valueFrom: {
      secretKeyRef: {
        name: file,
        key: key,
      },
    },
  }
}
