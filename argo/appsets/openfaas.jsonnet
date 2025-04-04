local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local util = import '../lib/util.libsonnet';

local openfaasSource = helm.new('openfaas',
  repoURL="https://openfaas.github.io/faas-netes/",
  chart="openfaas",
  targetRevision="14.2.102",
  values={
    // Add the dashboard to the function ingress
    ingress: util.ingress('fn') {
      tls+: [{
        hosts: ['openfaas.{{ .domain }}'],
        secretName: 'openfaas-tls',
      }],
      hosts: [{
        host: 'openfaas.{{ .domain }}',
        http: { paths: [{
          path: '/',
          pathType: 'Prefix',
          backend: { service: {
            name: 'dashboard',
            port: { number: 8080 },
          }},
        }]},
      }, {
        host: 'fn.{{ .domain }}',
        http: { paths: [{
          path: '/',
          pathType: 'Prefix',
          backend: { service: {
            name: 'gateway',
            port: { number: 8080 },
          }},
        }]}
      }],
    },
  },
);

local extraObjects = helm.extraObjects('openfaas')

appset.new('openfaas', 'openfaas')
+ appset.addSource(openfaasSource)
+ appset.addSource(extraObjects)
