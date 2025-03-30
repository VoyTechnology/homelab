local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local util = import '../lib/util.libsonnet';

local ollamaSource = helm.new('ollama',
  repoURL="https://otwld.github.io/ollama-helm/",
  chart="ollama",
  targetRevision="1.12.0",
);

local openWebUISource = helm.new('open-webui',
  repoURL="https://helm.openwebui.com/",
  chart="open-webui",
  targetRevision="5.24.0",
  values={
    ingress: util.ingress('ai', class='internal-shared'),
  }
);

appset.new('ai', 'ai')
+ appset.addSource(ollamaSource)
+ appset.addSource(openWebUISource)
