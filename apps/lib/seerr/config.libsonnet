{
  _config+:: {
    // Owned by the `media` Kustomization, so it is not created here.
    namespace: 'media',
    host: 'request.voy.technology',
    url: 'https://' + self.host,
    oidcSecretName: 'seerr-pocketid',
  },
}
