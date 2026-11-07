local helm = (import 'github.com/grafana/jsonnet-libs/tanka-util/helm.libsonnet').new(std.thisFile)
             // Leave labels as the chart renders them (no Helmraiser label), or the pods would roll.
             + { defaultLabels:: {} };

local hooked(o) = std.objectHas(o.metadata, 'annotations') && std.objectHas(o.metadata.annotations, 'helm.sh/hook');
// Flux does not run Helm hooks. Applied as plain objects they would be harmful (the pre-delete
// `longhorn-uninstall` Job uninstalls Longhorn), so they are dropped.
local withoutHooks(objs) = { [k]: objs[k] for k in std.objectFields(objs) if !hooked(objs[k]) };
// CRDs hold every Volume, Replica and Setting: never let Flux prune them.
local keepCrds(objs) = {
  [k]: if objs[k].kind == 'CustomResourceDefinition'
  then objs[k] { metadata+: { annotations+: { 'kustomize.toolkit.fluxcd.io/prune': 'disabled' } } }
  else objs[k]
  for k in std.objectFields(objs)
};

{
  // Rendered from the upstream chart (vendored by `tk tool charts vendor`, see chartfile.yaml): Longhorn
  // has its own upgrade procedure, so the chart stays the source of truth instead of hand-written objects.
  chart: keepCrds(withoutHooks(helm.template($._config.release, './charts/longhorn', {
    namespace: $._config.namespace,
    includeCrds: true,
    values: {
      csi: { kubeletRootDir: $._config.kubeletRootDir },
      persistence: { defaultClassReplicaCount: $._config.defaultReplicaCount },
      ingress: {
        enabled: true,
        ingressClassName: 'internal-login',
        host: $._config.host,
        tls: true,
        tlsSecret: 'longhorn-tls',
        secureBackends: true,
        annotations: { 'cert-manager.io/cluster-issuer': 'letsencrypt' },
      },
    },
  }))),
}
