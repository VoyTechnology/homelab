{
  _config+:: {
    namespace: 'paperless',
    host: 'docs.bednarzak.com',
    url: 'https://' + self.host,
    // Documents live on this node, in the host directory; the pod is pinned to the node.
    nodeName: 's1-bet1',
    hostPath: '/storage/Documents',
    // Pocket ID is the identity provider for login.
    oidcHost: 'login.bednarzak.com',
    pocketidNamespace: 'pocketid',
    oidcSecretName: 'paperless-oidc-credentials',
  },
}
