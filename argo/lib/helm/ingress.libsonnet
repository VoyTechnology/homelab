{
  // creates a new ingress
  new(name, domain=null, class='internal'): {
    local _domain = if domain == null then (name + '.{{ .domain }}') else domain,
    enabled: true,
    ingressClassName: class,
    annotations: {
      'cert-manager.io/cluster-issuer': 'letsencrypt',
    },
    hosts: [_domain],
    tls: [{
      secretName: name + '-tls',
      hosts: [_domain],
    }],
  },

  // withHostList changes the host list into objects
  withHostObjects(paths=[{ path: '/', pathType: 'ImplementationSpecific' }]): {
    hosts: [{ host: host, paths: paths } for host in super.hosts],
  },

  withClassName: {
    className: super.ingressClassName,
  },
}
