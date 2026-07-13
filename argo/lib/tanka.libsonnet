{
  new(
    name,
    repoURL='git@github.com:Voytechnology/homelab.git',
    path=null,
    targetRevision='HEAD',
    data={},
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
        {
          name: 'EXTRA_ARGS',
          value:
            std.join(' ', [
              '--tla-str',
              'clusterName={{ .cluster }}',
              '--tla-str',
              'apiServer={{ .server }}',
              '--tla-code',
              'data=%s' % std.toString(data),
            ]),
        },
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
