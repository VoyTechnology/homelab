// Scaling: replica counts and CPU/memory requests and limits.
local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';

local deployment = k.apps.v1.deployment;
local statefulSet = k.apps.v1.statefulSet;

// resources sets CPU/memory requests and a memory limit (no CPU limit besides the ruler's).
local resources(cpu, memory, memoryLimit) =
  k.util.resourcesRequests(cpu, memory) + k.util.resourcesLimits(null, memoryLimit);

{
  _config+:: {
    // Garage.
    resources: { requests: { cpu: '50m', memory: '128Mi' }, limits: { memory: '512Mi' } },

    // Scale down to 1 replica for the homelab setup.
    memcached_frontend_replicas: 1,
    memcached_index_queries_replicas: 1,
    memcached_chunks_replicas: 1,
    memcached_metadata_replicas: 1,
    memcached_range_vector_splitting_replicas: 1,
  },

  compactor_statefulset+: statefulSet.mixin.spec.withReplicas(1),
  distributor_deployment+: deployment.mixin.spec.withReplicas(1),
  ingester_statefulset+: statefulSet.mixin.spec.withReplicas(1),
  querier_deployment+: deployment.mixin.spec.withReplicas(1),
  query_frontend_deployment+: deployment.mixin.spec.withReplicas(1),
  query_scheduler_deployment+: deployment.mixin.spec.withReplicas(1),
  store_gateway_statefulset+: statefulSet.mixin.spec.withReplicas(1),
  ruler_deployment+: deployment.mixin.spec.withReplicas(1),

  // The Mimir library defaults assume a production cluster (e.g. 25Gi ingester,
  // 24Gi querier). The workers are Raspberry Pis with ~4GiB each, so cap everything.
  compactor_container+: resources('100m', '256Mi', '1Gi'),
  distributor_container+: resources('100m', '256Mi', '768Mi'),
  ingester_container+: resources('100m', '512Mi', '1Gi'),
  querier_container+: resources('100m', '128Mi', '768Mi'),
  query_frontend_container+: resources('100m', '128Mi', '384Mi'),
  query_scheduler_container+: resources('50m', '64Mi', '256Mi'),
  store_gateway_container+: resources('100m', '256Mi', '768Mi'),
  ruler_container+: resources('100m', '128Mi', '512Mi') + k.util.resourcesLimits('1', '512Mi'),

  // Memcached sizes are derived from memory_limit_mb (the library defaults to 6GiB for chunks).
  memcached_chunks+: { memory_limit_mb: 256 },
  memcached_frontend+: { memory_limit_mb: 64 },
  memcached_index_queries+: { memory_limit_mb: 64 },
  memcached_metadata+: { memory_limit_mb: 32 },
}
