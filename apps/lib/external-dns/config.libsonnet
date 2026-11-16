{
  _config+:: {
    // Created by Ansible, so Flux does not manage (or prune) it.
    namespace: 'external-dns-system',
    sources: ['service', 'ingress', 'gateway-httproute'],
  },
}
