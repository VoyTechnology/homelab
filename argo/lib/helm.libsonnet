{
  new(
    name,
    repoURL='git@github.com:Voytechnology/homelab.git',
    targetRevision='HEAD',
    values={},
  ): {
    repoURL: repoURL,
    targetRevision: targetRevision,
    path: 'argo/apps/%s' % name,
    helm: {
      releaseName: name,
      ignoreMissingValueFiles: true,
      valueFiles: [
        'argo/apps/%s/{{ .cluster }}.values.yaml' % name,
      ],
      valuesObject: values,
    }
  }
}
