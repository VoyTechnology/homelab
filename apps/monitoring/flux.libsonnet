// Flux's own state for the Flux dashboards (see `flux` in mixins.libsonnet): kube-state-metrics turns the
// Flux custom resources into gotk_resource_info. The controllers' own gotk_* and controller_runtime_* metrics
// need nothing here, Alloy scrapes them through their prometheus.io annotations like any other pod.
local k = import 'k.libsonnet';

local configMap = k.core.v1.configMap;
local volume = k.core.v1.volume;
local volumeMount = k.core.v1.volumeMount;

// What each kind carries on top of the labels all of them share. Only the kinds installed by default:
// the image-* controllers are not part of this Flux install.
local resources = [
  { group: 'kustomize.toolkit.fluxcd.io', version: 'v1', kind: 'Kustomization', plural: 'kustomizations', labels: { revision: ['status', 'lastAppliedRevision'], source_name: ['spec', 'sourceRef', 'name'] } },
  { group: 'helm.toolkit.fluxcd.io', version: 'v2', kind: 'HelmRelease', plural: 'helmreleases', labels: { revision: ['status', 'history', '0', 'chartVersion'], chart_name: ['status', 'history', '0', 'chartName'], chart_app_version: ['status', 'history', '0', 'appVersion'], chart_ref_name: ['spec', 'chartRef', 'name'], chart_source_name: ['spec', 'chart', 'spec', 'sourceRef', 'name'] } },
  { group: 'source.toolkit.fluxcd.io', version: 'v1', kind: 'GitRepository', plural: 'gitrepositories', labels: { revision: ['status', 'artifact', 'revision'], url: ['spec', 'url'] } },
  { group: 'source.toolkit.fluxcd.io', version: 'v1', kind: 'Bucket', plural: 'buckets', labels: { revision: ['status', 'artifact', 'revision'], endpoint: ['spec', 'endpoint'], bucket_name: ['spec', 'bucketName'] } },
  { group: 'source.toolkit.fluxcd.io', version: 'v1', kind: 'HelmRepository', plural: 'helmrepositories', labels: { revision: ['status', 'artifact', 'revision'], url: ['spec', 'url'] } },
  { group: 'source.toolkit.fluxcd.io', version: 'v1', kind: 'HelmChart', plural: 'helmcharts', labels: { revision: ['status', 'artifact', 'revision'], chart_name: ['spec', 'chart'], chart_version: ['spec', 'version'] } },
  { group: 'source.toolkit.fluxcd.io', version: 'v1', kind: 'OCIRepository', plural: 'ocirepositories', labels: { revision: ['status', 'artifact', 'revision'], url: ['spec', 'url'] } },
  { group: 'notification.toolkit.fluxcd.io', version: 'v1beta3', kind: 'Alert', plural: 'alerts', ready: false, labels: {} },
  { group: 'notification.toolkit.fluxcd.io', version: 'v1beta3', kind: 'Provider', plural: 'providers', ready: false, labels: {} },
  { group: 'notification.toolkit.fluxcd.io', version: 'v1', kind: 'Receiver', plural: 'receivers', labels: { webhook_path: ['status', 'webhookPath'] } },
];

local stateMetric(r) = {
  groupVersionKind: { group: r.group, version: r.version, kind: r.kind },
  metricNamePrefix: 'gotk',
  metrics: [{
    name: 'resource_info',
    help: 'The current state of a Flux %s resource.' % r.kind,
    each: { type: 'Info', info: { labelsFromPath: { name: ['metadata', 'name'] } } },
    // exported_namespace, not namespace: the Flux dashboards query it, and it keeps the object's namespace
    // apart from the namespace of the pod Alloy scrapes.
    labelsFromPath: {
      exported_namespace: ['metadata', 'namespace'],
      suspended: ['spec', 'suspend'],
    } + (if std.get(r, 'ready', true) then { ready: ['status', 'conditions', '[type=Ready]', 'status'] } else {}) + r.labels,
  }],
};

{
  flux_state_config_map:
    configMap.new('kube-state-metrics-flux', {
      'flux.yaml': std.manifestYamlDoc({
        kind: 'CustomResourceStateMetrics',
        spec: { resources: [stateMetric(r) for r in resources] },
      }),
    }),

  // The custom resources come on top of the built-in collectors, which the kubernetes dashboards need.
  kube_state_metrics_deployment+:
    k.apps.v1.deployment.mixin.spec.template.spec.withVolumesMixin([
      volume.fromConfigMap('flux', $.flux_state_config_map.metadata.name),
    ])
    + {
      spec+: { template+: { spec+: { containers: [
        c {
          args+: ['--custom-resource-state-config-file=/etc/kube-state-metrics/flux.yaml'],
          volumeMounts+: [volumeMount.new('flux', '/etc/kube-state-metrics', true)],
        }
        for c in super.containers
      ] } } },
    },

  kube_state_metrics_cluster_role+: {
    rules+: [{
      apiGroups: std.set([r.group for r in resources]),
      resources: [r.plural for r in resources],
      verbs: ['list', 'watch'],
    }],
  },
}
