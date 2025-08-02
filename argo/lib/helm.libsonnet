{
  new(
    name,
    repoURL='git@github.com:Voytechnology/homelab.git',
    chart=null,
    targetRevision='HEAD',
    path=null,
    values={},
    valuesApp='',
  ): {
    repoURL: repoURL,
    targetRevision: targetRevision,
    [if chart != null then 'chart']: chart,
    [if chart == null then 'path']:
      if path == null then
        'argo/apps/%s' % name
      else
        path,
    helm: {
      valuesPath::
        if valuesApp == '' then
          '$values/argo/apps/%s' % name
        else
          '$values/argo/apps/%s' % valuesApp,

      releaseName: name,
      passCredentials: true,
      ignoreMissingValueFiles: true,
      valueFiles: [
        '%s/values.yaml' % self.valuesPath,
        '%s/default.values.yaml' % self.valuesPath,
        '%s/{{ .cluster }}.values.yaml' % self.valuesPath,
      ],
      valuesObject: values,
    },
  },
  // extraObjects is an an abstracted source used to load extra objects
  extraObjects(
    name,
    repoURL='git@github.com:Voytechnology/homelab.git',
    path='charts/extra-objects',
    targetRevision='HEAD',
    values={},
  ): {
    repoURL: repoURL,
    targetRevision: targetRevision,
    path: path,
    helm: {
      releaseName: '%s-extra-objects' % name,
      passCredentials: true,
      ignoreMissingValueFiles: true,
      valueFiles: [
        '$values/argo/apps/%s/values.yaml' % name,
        '$values/argo/apps/%s/default.values.yaml' % name,
        '$values/argo/apps/%s/extra.values.yaml' % name,
        '$values/argo/apps/%s/{{ .cluster }}.values.yaml' % name,
      ],
      valuesObject: values,
    }
  }
}
