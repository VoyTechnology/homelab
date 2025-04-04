local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local util = import '../lib/util.libsonnet';

local ollamaSource = helm.new('ollama',
  repoURL="https://otwld.github.io/ollama-helm/",
  chart="ollama",
  targetRevision="1.12.0",
  valuesApp='ai',
);

local openWebUISource = helm.new('open-webui',
  repoURL="https://helm.openwebui.com/",
  chart="open-webui",
  targetRevision="6.0.0",
  valuesApp='ai',
  values={
    ollama: { enabled: false },
    ingress: {
      enabled: true,
      className: 'internal-shared',
      host: 'ai.{{ .domain }}',
      tls: true,
      annotations: {
        'cert-manager.io/cluster-issuer': 'letsencrypt',
      },
    },
  }
);

appset.new('ai', 'ai')
+ appset.addSource(ollamaSource)
+ appset.addSource(openWebUISource)
