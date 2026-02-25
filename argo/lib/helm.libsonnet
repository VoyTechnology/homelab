{
  new(
    name,
    repoURL='git@github.com:Voytechnology/homelab.git',
    chart=null,
    targetRevision='HEAD',
    path=null,
    values={},
    valuesApp='',
    valuesPrefix='',
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

      // automatically concat with dot
      valuesPrefix::
        if valuesPrefix != '' then
          '%s.' % valuesPrefix
        else '',

      valueFiles: [
        '%s/%svalues.yaml' % [self.valuesPath, self.valuesPrefix],
        '%s/%sdefault.values.yaml' % [self.valuesPath, self.valuesPrefix],
        '%s/%s{{ .cluster }}.values.yaml' % [self.valuesPath, self.valuesPrefix],
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
    overrides=null,
    values={},
    valuesPrefix=''
  ): {
    repoURL: repoURL,
    targetRevision: targetRevision,
    path: path,
    helm: {
      releaseName: '%s-extra-objects' % name,
      passCredentials: true,
      ignoreMissingValueFiles: true,

      // automatically concat with dot
      valuesPrefix::
        if valuesPrefix != '' then
          '%s.' % valuesPrefix
        else
          '',

      valueFiles: [
        '$values/argo/apps/%s/%sextra.values.yaml' % [name, valuesPrefix],
        '$values/argo/apps/%s/%s{{ .cluster }}.extra.values.yaml' % [name, valuesPrefix],
      ],
      valuesObject: values + { extraObjects: overrides },
    },
  },
}
