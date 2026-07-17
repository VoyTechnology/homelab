{
  new(
    name,
    repoURL='git@github.com:Voytechnology/homelab.git',
    path=null,
    targetRevision='HEAD',
    namespace='default',
    overrides={},
  ): {
    repoURL: repoURL,
    targetRevision: targetRevision,
    path:
      if path == null then
        'argo/apps/%s' % name
      else
        path,
    plugin: {
      # name: ommitted, as it uses the jsonnetfile.json as the plugin matcher
      env: [
        { name: 'TK_ENV', value: '{{ .cluster }}/%(namespace)s/%(app)s' % {
          app: name, namespace: namespace,
        } },
        { name: 'TANKA_APISERVER', value: '{{ .server }}' },
        { name: 'TANKA_NAMESPACE', value: namespace },
        { name: 'TANKA_CLUSTER', value: '{{ .cluster }}' },
        { name: 'TANKA_APP', value: name },
        { name: 'TANKA_OVERRIDES', value: std.toString(overrides) },
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
