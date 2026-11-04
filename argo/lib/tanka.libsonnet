{
  // Native layout: apps/<name>/environments/<cluster>/ is a committed Tanka
  // environment, so nothing is generated and no overrides are passed in.
  // The namespace lives in the environment's spec.json.
  newNative(
    name,
    repoURL='git@github.com:Voytechnology/homelab.git',
    targetRevision='HEAD',
  ): {
    repoURL: repoURL,
    targetRevision: targetRevision,
    path: 'apps/%s' % name,
    plugin: {
      env: [
        { name: 'TANKA_CLUSTER', value: '{{ .cluster }}' },
        { name: 'TANKA_APP', value: name },
        { name: 'TANKA_ENV_DIR', value: 'environments/{{ .cluster }}' },
      ],
    },
  },

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
}
