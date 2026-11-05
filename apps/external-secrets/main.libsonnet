local flux = import 'github.com/jsonnet-libs/fluxcd-libsonnet/2.9.4/main.libsonnet';
local es = import 'github.com/jsonnet-libs/external-secrets-libsonnet/1.3/main.libsonnet';
local operator = import 'github.com/VoyTechnology/home-libsonnet/external-secrets/main.libsonnet';

local kustomization = flux.kustomize.v1.kustomization;
local css = es.nogroup.v1.clusterSecretStore;

// External Secrets Operator is cluster-wide, so it lives in kube-system (an
// existing namespace Flux must not manage or prune).
local namespace = 'kube-system';

// Every Kubernetes object in a (nested) library value.
local objects(o) =
  if std.isObject(o) && std.objectHas(o, 'kind') then [o]
  else if std.isObject(o) then std.flattenArrays([objects(o[f]) for f in std.objectFields(o)])
  else [];

// Returns files keyed by their path in homelab-manifests; scripts/render-flux.sh
// writes each value as YAML.
{
  new(cluster)::
    local dir(unit) = 'apps/%s/%s' % [cluster, unit];
    local unit(name) =
      kustomization.new(name)
      + kustomization.metadata.withNamespace('flux-system')
      + kustomization.spec.withInterval('10m')
      + kustomization.spec.withPath('./' + dir(name))
      + kustomization.spec.withPrune(true)
      + kustomization.spec.withWait(true)
      + kustomization.spec.sourceRef.withKind('GitRepository')
      + kustomization.spec.sourceRef.withName('flux-system');
    local deployed = operator { _config+:: { namespace: namespace } };
    {
      ['clusters/%s/apps/external-secrets.yaml' % cluster]: unit('external-secrets'),
      ['clusters/%s/apps/external-secrets-config.yaml' % cluster]:
        // The store needs the operator's CRDs, so it is its own unit.
        unit('external-secrets-config')
        + kustomization.spec.withDependsOn([{ name: 'external-secrets' }]),

      [dir('external-secrets-config') + '/clustersecretstore.yaml']:
        css.new('cluster-secrets')
        + css.spec.provider.kubernetes.server.withUrl('https://kubernetes.default.svc')
        + css.spec.provider.kubernetes.server.caProvider.withType('ConfigMap')
        + css.spec.provider.kubernetes.server.caProvider.withName('kube-root-ca.crt')
        + css.spec.provider.kubernetes.server.caProvider.withKey('ca.crt')
        + css.spec.provider.kubernetes.server.caProvider.withNamespace(namespace)
        + css.spec.provider.kubernetes.auth.serviceAccount.withName(deployed.esServiceAccount.metadata.name)
        + css.spec.provider.kubernetes.auth.serviceAccount.withNamespace(namespace)
        + css.spec.provider.kubernetes.withRemoteNamespace(namespace),
    } + {
      ['%s/%s-%s.yaml' % [dir('external-secrets'), std.asciiLower(o.kind), o.metadata.name]]: o
      for o in objects(deployed)
    },
}
