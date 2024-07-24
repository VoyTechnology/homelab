{
  apiVersion: 'argoproj.io/v1alpha1',
  kind: 'ApplicationSet',
  metadata: {
    name: 'monitoring',
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
        name: '{{ .cluster }}-monitoring',
        namespace: 'argocd',
        labels: {
          'argocd.argoproj.io/application-set-name': 'monitoring',
        },
      },
      spec: {
        destination: {
          server: '{{ .server }}',
          namespace: 'monitoring',
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
        sources: [
          {
            repoURL: 'git@github.com:Voytechnology/homelab.git',
            targetRevision: '{{ .values.targetRevision }}',
            path: 'argo/apps/monitoring',
            helm: {
              releaseName: 'monitoring',
              ignoreMissingValueFiles: true,
              valueFiles: [
                'argo/apps/monitoring/{{ .cluster }}.values.yaml',
              ],
              valuesObject: {
                grafana: {
                  ingress: {
                    hosts: ['grafana.{{ .domain }}'],
                    tls: [{
                      secretName: 'grafana-tls', hosts: ['grafana.{{ .domain }}']
                    }],
                  },
                  'grafana.ini': {
                    server: {
                      domain: 'grafana.{{ .domain }}',
                      root_url: 'https://grafana.{{ .domain }}',
                    },
                    'auth.generic_oauth': {
                      auth_url: 'https://login.{{ .domain }}/auth',
                      token_url: 'https://login.{{ .domain }}/token',
                      api_url: 'https://login.{{ .domain }}/userinfo',
                    },
                  },
                },
                mimir: {
                  ingress: {
                    hosts: ['metrics.{{ .domain }}'],
                    tls: [{
                      secretName: 'mimir-tls', hosts: ['metrics.{{ .domain }}']
                    }],
                  },
                },
              },
            },
          },
        ],
      },
    },
  },
}
