local es = import 'github.com/jsonnet-libs/external-secrets-libsonnet/1.3/main.libsonnet';
local operator = import 'github.com/VoyTechnology/home-libsonnet/external-secrets/main.libsonnet';

local css = es.nogroup.v1.clusterSecretStore;

// The operator from home-libsonnet plus a ClusterSecretStore exposing the
// kube-system secrets to the rest of the cluster.
operator {
  local cfg = $._config,

  esClusterSecretStore:
    css.new('cluster-secrets')
    + css.spec.provider.kubernetes.server.withUrl('https://kubernetes.default.svc')
    + css.spec.provider.kubernetes.server.caProvider.withType('ConfigMap')
    + css.spec.provider.kubernetes.server.caProvider.withName('kube-root-ca.crt')
    + css.spec.provider.kubernetes.server.caProvider.withKey('ca.crt')
    + css.spec.provider.kubernetes.server.caProvider.withNamespace(cfg.namespace)
    + css.spec.provider.kubernetes.auth.serviceAccount.withName($.esServiceAccount.metadata.name)
    + css.spec.provider.kubernetes.auth.serviceAccount.withNamespace(cfg.namespace)
    + css.spec.provider.kubernetes.withRemoteNamespace(cfg.namespace),
}
