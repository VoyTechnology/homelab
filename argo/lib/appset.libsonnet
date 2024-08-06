{
  new(name, namespace): {
    apiVersion: 'argoproj.io/v1alpha1',
    kind: 'ApplicationSet',
    metadata: {
      name: name,
      namespace: 'argocd'
    },
    spec: {
      goTemplate: true,
      goTemplateOptions: ["missingkey=error"],
      generators: [
        {
          git: {
            repoURL: 'git@github.com:Voytechnology/homelab.git',
            revision: 'HEAD',
            files: [{path: 'argo/clusters/*.yaml'}],
            values: { targetRevision: 'HEAD' },
          },
        },
      ],

      template: {
        metadata: {
          finalizers: ['resources-finalizer.argoproj.io'],
          name: '{{ .cluster }}-%s' % name,
          namespace: 'argocd',
          labels: {
            'argocd.argoproj.io/application-set-name': name,
          },
        },
        spec: {
          destination: {
            server: '{{ .server }}',
            namespace: namespace,
          },
          project: 'apps',
          syncPolicy: {
            automated: {
              prune: true,
              selfHeal: true,
            },
            syncOptions: [
              'CreateNamespace=true',
            ],
            retry: {
              limit: 10,
              backoff: {
                duration: '10s',
                factor: 2,
                maxDuration: '30m',
              }
            },
          },
          revisionHistoryLimit: 3,
          sources: [],
        },
      },
    },
  },

  addSource(source): {
    spec+: {
      template+: {
        spec+: {
          sources+: [source],
        },
      },
    },
  },
}
