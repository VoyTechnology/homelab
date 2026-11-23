// Scaling: replica counts and CPU/memory requests and limits.
local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';

local deployment = k.apps.v1.deployment;
local statefulSet = k.apps.v1.statefulSet;

// resources sets CPU/memory requests and a memory limit (no CPU limit besides the ruler's).
local resources(cpu, memory, memoryLimit) =
  k.util.resourcesRequests(cpu, memory) + k.util.resourcesLimits(null, memoryLimit);

// The library asks for 500m CPU per memcached and 50m for its exporter; both idle at ~1m.
local memcachedCpu = { cpu_requests: '20m', exporter_cpu_requests: '5m' };

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
  // Observed over 30 days: compactor ~100Mi (peak 145Mi), ingester ~460Mi, querier ~280Mi (peak 320Mi),
  // query-frontend ~70Mi, query-scheduler ~50Mi, store-gateway ~110Mi, ruler ~340Mi.
  compactor_container+: resources('20m', '256Mi', '1Gi'),
  // 768Mi was OOMKilled at startup.
  distributor_container+: resources('100m', '1Gi', '1Gi'),
  ingester_container+: resources('50m', '512Mi', '1Gi'),
  querier_container+: resources('20m', '384Mi', '768Mi'),
  query_frontend_container+: resources('10m', '128Mi', '384Mi'),
  query_scheduler_container+: resources('10m', '64Mi', '256Mi'),
  // Mimir derives GOMEMLIMIT from the memory request, so keep it well above the ~110Mi in use.
  store_gateway_container+: resources('20m', '192Mi', '768Mi'),
  ruler_container+: resources('50m', '384Mi', '512Mi') + k.util.resourcesLimits('1', '512Mi'),

  // Memcached sizes are derived from memory_limit_mb (the library defaults to 6GiB for chunks).
  memcached_chunks+: { memory_limit_mb: 256 } + memcachedCpu,
  memcached_frontend+: { memory_limit_mb: 64 } + memcachedCpu,
  memcached_index_queries+: { memory_limit_mb: 64 } + memcachedCpu,
  memcached_metadata+: { memory_limit_mb: 32 } + memcachedCpu,
}
