local flux = import 'github.com/jsonnet-libs/fluxcd-libsonnet/2.9.4/main.libsonnet';
local es = import 'github.com/jsonnet-libs/external-secrets-libsonnet/1.3/main.libsonnet';

local repository = flux.source.v1.helmRepository;
local release = flux.helm.v2.helmRelease;
local kustomization = flux.kustomize.v1.kustomization;
local css = es.nogroup.v1.clusterSecretStore;

// External Secrets Operator is cluster-wide, so it lives in kube-system (an
// existing namespace Flux must not manage or prune).
local namespace = 'kube-system';
// The chart derives the service account name from the release name.
local releaseName = 'externalsecrets';

// Returns files keyed by their path in homelab-manifests; scripts/render-flux.sh
// writes each value as YAML.
{
  new(
    cluster,
    // renovate: datasource=helm depName=external-secrets registryUrl=https://charts.external-secrets.io
    targetRevision='0.18.2',
  )::
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
    {
      ['clusters/%s/apps/external-secrets.yaml' % cluster]: unit('external-secrets'),

      [dir('external-secrets') + '/helmrepository.yaml']:
        repository.new('external-secrets')
        + repository.metadata.withNamespace('flux-system')
        + repository.spec.withInterval('1h')
        + repository.spec.withUrl('https://charts.external-secrets.io'),

      [dir('external-secrets') + '/helmrelease.yaml']:
        release.new('external-secrets')
        + release.metadata.withNamespace('flux-system')
        + release.spec.withInterval('1h')
        + release.spec.withReleaseName(releaseName)
        + release.spec.withTargetNamespace(namespace)
        + release.spec.withStorageNamespace(namespace)
        + release.spec.chart.spec.withChart('external-secrets')
        + release.spec.chart.spec.withVersion(targetRevision)
        + release.spec.chart.spec.sourceRef.withKind('HelmRepository')
        + release.spec.chart.spec.sourceRef.withName('external-secrets')
        + release.spec.chart.spec.sourceRef.withNamespace('flux-system'),

      // The store needs the operator's CRDs, so it is its own unit.
      ['clusters/%s/apps/external-secrets-config.yaml' % cluster]:
        unit('external-secrets-config')
        + kustomization.spec.withDependsOn([{ name: 'external-secrets' }]),

      [dir('external-secrets-config') + '/clustersecretstore.yaml']:
        css.new('cluster-secrets')
        + css.spec.provider.kubernetes.server.withUrl('https://kubernetes.default.svc')
        + css.spec.provider.kubernetes.server.caProvider.withType('ConfigMap')
        + css.spec.provider.kubernetes.server.caProvider.withName('kube-root-ca.crt')
        + css.spec.provider.kubernetes.server.caProvider.withKey('ca.crt')
        + css.spec.provider.kubernetes.server.caProvider.withNamespace(namespace)
        + css.spec.provider.kubernetes.auth.serviceAccount.withName('%s-external-secrets' % releaseName)
        + css.spec.provider.kubernetes.auth.serviceAccount.withNamespace(namespace)
        + css.spec.provider.kubernetes.withRemoteNamespace(namespace),
    },
}
