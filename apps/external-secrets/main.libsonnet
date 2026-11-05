local flux = import '../lib/flux.libsonnet';
local es = import 'github.com/jsonnet-libs/external-secrets-libsonnet/1.3/main.libsonnet';
local css = es.nogroup.v1.clusterSecretStore;

// External Secrets Operator is a cluster-wide operator, so it lives in
// kube-system (an existing namespace we must not manage or prune).
local namespace = 'kube-system';
// Chart release name; the chart derives the service account name from it.
local releaseName = 'externalsecrets';

{
  new(
    cluster,
    // renovate: datasource=helm depName=external-secrets registryUrl=https://charts.external-secrets.io
    targetRevision='0.18.2',
  )::
    flux.render(cluster, [
      flux.unit('external-secrets', [
        flux.helmRepository('external-secrets', 'https://charts.external-secrets.io'),
        flux.helmRelease(
          'external-secrets',
          namespace,
          chart='external-secrets',
          version=targetRevision,
          repository='external-secrets',
          releaseName=releaseName,
        ),
      ]),

      // The ClusterSecretStore needs the operator's CRDs, so it is its own unit.
      flux.unit('external-secrets-config', [
        css.new('cluster-secrets')
        + css.spec.provider.kubernetes.server.withUrl('https://kubernetes.default.svc')
        + css.spec.provider.kubernetes.server.caProvider.withType('ConfigMap')
        + css.spec.provider.kubernetes.server.caProvider.withName('kube-root-ca.crt')
        + css.spec.provider.kubernetes.server.caProvider.withKey('ca.crt')
        + css.spec.provider.kubernetes.server.caProvider.withNamespace(namespace)
        + css.spec.provider.kubernetes.auth.serviceAccount.withName('%s-external-secrets' % releaseName)
        + css.spec.provider.kubernetes.auth.serviceAccount.withNamespace(namespace)
        + css.spec.provider.kubernetes.withRemoteNamespace(namespace),
      ], dependsOn=['external-secrets']),
    ]),
}
