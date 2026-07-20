local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';
local mimir = import 'mimir/mimir.libsonnet';

local deployment = k.apps.v1.deployment;
local statefulSet = k.apps.v1.statefulSet;

// withSyncWave adds the sync-wave annotations to the metadata of the resource.
local withSyncWave(wave) = {
  metadata+: { annotations+: { 'argocd.argoproj.io/sync-wave': std.toString(wave) } },
};

mimir {
  _config+:: {
    namespace: $._namespace,
    cluster: $._cluster,
    external_url: 'http://metrics-mimir-gateway.%s.svc.cluster.local' % $._namespace,

    aws_region: 'us-east-1', # unused
    storage_backend: 's3',
    storage_s3_endpoint: 'seaweedfs-s3.%s.svc.cluster.local:8333' % $._namespace,
    blocks_storage_bucket_name: 'mimir',
    memberlist_zone_aware_routing_enabled: false,

    alertmanager_data_disk_class: null,
    alertmanager_data_disk_size: '1Gi',

    ingester_data_disk_class: null,
    ingester_data_disk_size: '1Gi',
    ingester_allow_multiple_replicas_on_same_node: true,

    store_gateway_data_disk_class: null,
    store_gateway_data_disk_size: '1Gi',
    store_gateway_allow_multiple_replicas_on_same_node: true,

    compactor_data_disk_class: null,
    compactor_data_disk_size: '2Gi',
  },

  compactor_statefulset+: statefulSet.mixin.spec.withReplicas(1),
  distributor_deployment+: deployment.mixin.spec.withReplicas(1),
  ingester_statefulset+: statefulSet.mixin.spec.withReplicas(1),
  querier_deployment+: deployment.mixin.spec.withReplicas(1),
  query_frontend_deployment+: deployment.mixin.spec.withReplicas(1),
  store_gateway_statefulset+: statefulSet.mixin.spec.withReplicas(1),
  query_scheduler_deployment+: deployment.mixin.spec.withReplicas(1),

  compactor_container+: k.util.resourcesRequests('100m', '128Mi'),
  distributor_container+: k.util.resourcesRequests('100m', '128Mi'),
  ingester_container+: k.util.resourcesRequests('100m', '128Mi'),
  querier_container+: k.util.resourcesRequests('100m', '128Mi'),
  query_frontend_container+: k.util.resourcesRequests('100m', '128Mi'),
  store_gateway_container+: k.util.resourcesRequests('100m', '128Mi'),
}

# Adjust the sync waves for each component to ensure that they are applied in the correct order
+ {
  distributor_deployment+: withSyncWave(1),
  distributor_service+: withSyncWave(2),
  distributor_pdb+: withSyncWave(1),
  ingester_statefulset+: withSyncWave(1),
  ingester_service+: withSyncWave(2),
  ingester_pdb+: withSyncWave(1),
  querier_deployment+: withSyncWave(1),
  querier_service+: withSyncWave(2),
  querier_pdb+: withSyncWave(1),
  query_frontend_deployment+: withSyncWave(1),
  query_frontend_service+: withSyncWave(2),
  query_frontend_pdb+: withSyncWave(1),
  query_scheduler_deployment+: withSyncWave(1),
  query_scheduler_service+: withSyncWave(2),
  query_scheduler_discovery_service+: withSyncWave(1),
  query_scheduler_pdb+: withSyncWave(1),
  compactor_statefulset+: withSyncWave(2),
  compactor_service+: withSyncWave(1),
  compactor_pdb+: withSyncWave(1),
  store_gateway_statefulset+: withSyncWave(1),
  store_gateway_service+: withSyncWave(2),
  store_gateway_pdb+: withSyncWave(1),
}

# Default values for the Tanka overrides. These can be overridden by the ArgoCD application.
+ {
  # Safe assumption, but should be passed in from the ArgoCD application.
  _namespace:: 'metrics-system',
  _cluster:: 'unknown',
}
