local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local ingress = import '../lib/helm/ingress.libsonnet';
local util = import '../lib/util.libsonnet';

local ollamaSource = helm.new(
  'ollama',
  repoURL='https://otwld.github.io/ollama-helm/',
  chart='ollama',
  targetRevision='1.12.0',
  valuesApp='ai',
  values={
    ingress: {
      enabled: true,
      hosts: [{
        host: 'ollama.{{ .domain }}',
        paths: [{ path: '/', pathType: 'Prefix' }],
      }],
    },
  }
);

local n8n = helm.new(
  'n8n',
  repoURL='oci://8gears.container-registry.com/library/n8n',
  chart='n8n',
  targetRevision='2.0.1',
  valuesApp='ai',
  valuesPrefix='n8n',
  values={
    main: { config: {
      host: 'n8n.{{ .domain }}',
    } },
    // TODO: Keep internal until fully setup.
    ingress: ingress.new('n8n')
             + ingress.withHostObjects()
             + ingress.withClassName,
  },
);

appset.new('ai', 'ai')
+ appset.addSource(ollamaSource)
+ appset.addSource(n8n)
