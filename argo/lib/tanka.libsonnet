{
  new(
    name,
    repoURL='git@github.com:Voytechnology/homelab.git',
    path=null,
    targetRevision='HEAD',
    namespace='default',
  ): {
    repoURL: repoURL,
    targetRevision: targetRevision,
    path:
      if path == null then
        'argo/apps/%s' % name
      else
        path,
    plugin: {
      name: 'tanka-plugin',
      env: [
        { name: 'TK_ENV', value: '' },
        { name: 'TANKA_APISERVER', value: '{{ .server }}' },
        { name: 'TANKA_NAMESPACE', value: namespace },
        { name: 'TANKA_CLUSTER', value: '{{ .cluster }}' },
      ],
    },
  },

  inline(name, namespace, clusterName, apiServer, data):
    {
      apiVersion: 'tanka.dev/v1alpha1',
      kind: 'Environment',
      metadata: {
        name: '%s/%s' % [clusterName, name],
      },
      spec: {
        apiServer: apiServer,
        namespace: namespace,
      },
      data: data,
    },
}