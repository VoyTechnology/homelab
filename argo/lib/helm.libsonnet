{
  new(
    name,
    repoURL='git@github.com:Voytechnology/homelab.git',
    chart=null,
    targetRevision='HEAD',
    path=null,
    values={},
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
      releaseName: name,
      passCredentials: true,
      ignoreMissingValueFiles: true,
      valueFiles: [
        '$values/argo/apps/%s/values.yaml' % name,
        '$values/argo/apps/%s/*.values.yaml' % name,
        '$values/argo/apps/%s/{{ .cluster }}/*.values.yaml' % name,
      ],
      valuesObject: values,
    },
  },
}
