local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';

local deployment = k.apps.v1.deployment;
local statefulSet = k.apps.v1.statefulSet;

// withScrapeAnnotations adds prometheus.io/scrape annotations to a pod
// template so Alloy's annotation-based pod discovery (see
// apps/monitoring/alloy-config.alloy) picks up the component's own /metrics
// endpoint. Without this, none of Mimir's components are scraped by
// anything, so Mimir never has its own cortex_*/mimir_* self-monitoring
// metrics (what the mimir-mixin dashboards query) even though it happily
// stores everything remote-written to it.
local withScrapeAnnotations = {
  spec+: { template+: { metadata+: { annotations+: {
    'prometheus.io/scrape': 'true',
    // Every component serves its own metrics on server_http_port (8080).
    'prometheus.io/port': '8080',
  } } } },
};

// resources sets CPU/memory requests and a memory limit (no CPU limit besides the ruler's).
local resources(cpu, memory, memoryLimit) =
  k.util.resourcesRequests(cpu, memory) + k.util.resourcesLimits(null, memoryLimit);

// The S3 key, from the Secret the config's $(VAR)s refer to. Only the components that touch the bucket need it.
local s3Credentials(secret) = {
  env+: [
    { name: 'S3_ACCESS_KEY_ID', valueFrom: { secretKeyRef: { name: secret, key: 'access-key-id' } } },
    { name: 'S3_SECRET_ACCESS_KEY', valueFrom: { secretKeyRef: { name: secret, key: 'secret-access-key' } } },
  ],
};

{
  // The volume claim templates are immutable, so growing the compactor's disk recreates the StatefulSet
  // (Flux's force annotation); its PVC is kept and expanded by hand.
  compactor_statefulset+: statefulSet.mixin.spec.withReplicas(1) + withScrapeAnnotations + {
    metadata+: { annotations+: { 'kustomize.toolkit.fluxcd.io/force': 'enabled' } },
  },
  distributor_deployment+: deployment.mixin.spec.withReplicas(1) + withScrapeAnnotations,
  ingester_statefulset+: statefulSet.mixin.spec.withReplicas(1) + withScrapeAnnotations,
  querier_deployment+: deployment.mixin.spec.withReplicas(1) + withScrapeAnnotations,
  query_frontend_deployment+: deployment.mixin.spec.withReplicas(1) + withScrapeAnnotations,
  store_gateway_statefulset+: statefulSet.mixin.spec.withReplicas(1) + withScrapeAnnotations,
  ruler_deployment+: deployment.mixin.spec.withReplicas(1) + withScrapeAnnotations,

  // query-scheduler.libsonnet unconditionally sets a hard podAntiAffinity
  // (unlike ingester/store-gateway, which respect the
  // *_allow_multiple_replicas_on_same_node config above) combined with
  // maxSurge(1)/maxUnavailable(0). On this single-node homelab cluster that
  // deadlocks forever: every pod-template change tries to schedule a second
  // query-scheduler pod on the same node before killing the old one, which
  // the anti-affinity rule forbids, leaving the new pod Pending and the
  // rollout permanently stuck ("exceeded its progress deadline"). Dropping
  // the anti-affinity rule isn't enough by itself: maxSurge(1)/
  // maxUnavailable(0) still tries to run two query-scheduler pods at once
  // during every rollout, which a one-node cluster has no spare capacity
  // for. Switch to Recreate so the old pod is torn down before the new one
  // is created, matching how single-node homelab rollouts actually work.
  query_scheduler_deployment+:
    deployment.mixin.spec.withReplicas(1)
    + deployment.mixin.spec.strategy.withType('Recreate')
    + {
      spec+: {
        strategy+: { rollingUpdate: null },
        template+: { spec+: { affinity: null } },
      },
    }
    + withScrapeAnnotations,

  // The Mimir library defaults assume a production cluster (e.g. 25Gi ingester,
  // 24Gi querier). The workers are Raspberry Pis with ~4GiB each, so cap everything.
  compactor_container+: resources('100m', '256Mi', '1Gi') + s3Credentials($._config.s3KeySecretName),
  distributor_container+: resources('100m', '256Mi', '768Mi'),
  ingester_container+: resources('100m', '512Mi', '1Gi') + s3Credentials($._config.s3KeySecretName),
  querier_container+: resources('100m', '128Mi', '768Mi') + s3Credentials($._config.s3KeySecretName),
  query_frontend_container+: resources('100m', '128Mi', '384Mi'),
  query_scheduler_container+: resources('50m', '64Mi', '256Mi'),
  store_gateway_container+: resources('100m', '256Mi', '768Mi') + s3Credentials($._config.s3KeySecretName),
  ruler_container+: resources('100m', '128Mi', '512Mi') + k.util.resourcesLimits('1', '512Mi') + s3Credentials($._config.s3KeySecretName),

  // The ingester's disk is 1Gi, so drop shipped blocks after 3h (default 13h) and have queries use the bucket from 2h30m.
  ingester_args+:: {
    'blocks-storage.tsdb.retention-period': '3h',
  },
  querier_args+:: {
    'querier.query-store-after': '2h30m',
    'querier.query-ingesters-within': '3h',
  },
  ruler_args+:: {
    'querier.query-store-after': '2h30m',
    'querier.query-ingesters-within': '3h',
  },

  // Memcached sizes are derived from memory_limit_mb (the library defaults to 6GiB for chunks).
  memcached_chunks+: { memory_limit_mb: 256 },
  memcached_frontend+: { memory_limit_mb: 64 },
  memcached_index_queries+: { memory_limit_mb: 64 },
  memcached_metadata+: { memory_limit_mb: 32 },

  // With the tiny setup in the homelab, podDisruptionBudget is causing issues with syncing.
  // Remove them for now and revisit in the future IF there are more nodes.
  distributor_pdb:: null,
  ingester_pdb:: null,
  querier_pdb:: null,
  query_frontend_pdb:: null,
  query_scheduler_pdb:: null,
  compactor_pdb:: null,
  store_gateway_pdb:: null,
  ruler_pdb:: null,
  memcached+:: { podDisruptionBudget:: null },
}
