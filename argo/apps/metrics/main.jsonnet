local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';
local mimir = import 'mimir/mimir.libsonnet';

local deployment = k.apps.v1.deployment;
local statefulSet = k.apps.v1.statefulSet;
local configMap = k.core.v1.configMap;

// withSyncWave adds the sync-wave annotations to the metadata of the resource.
local withSyncWave(wave) = {
  metadata+: { annotations+: { 'argocd.argoproj.io/sync-wave': std.toString(wave) } },
};

// The mimir-mixin's recording rules (the ones the mixin dashboards query,
// e.g. cluster_namespace_job_route:cortex_request_duration_seconds:sum_rate)
// are never evaluated unless something loads them into the ruler. Build them
// here from the same base mixin config imported by argo/apps/monitoring (see
// mixins.libsonnet there) so the recording rule names match exactly what the
// dashboards query. argo/apps/monitoring layers a `dashboards_default_latency_mode:
// 'native'` override on top of this config, but that key only picks the
// default value of a dashboard template variable -- it doesn't affect which
// recording rules get generated (that's the separate record_native default,
// already true in the vendored mixin), so the rule names built here still
// match. Alerting rules are intentionally left out for now:
// alertmanager_enabled is false below, and ruler.alertmanager-url points at
// a service that doesn't exist, so alert rules would just fail to notify.
local mimirMixinRecordingRules =
  (import 'mimir-mixin/config.libsonnet')
  + (import 'mimir-mixin/groups.libsonnet')
  + (import 'mimir-mixin/utils.libsonnet')
  + (import 'mimir-mixin/recording_rules.libsonnet');

// Mimir's ruler reads per-tenant rule files from <ruler_local_directory>/<tenant>/.
// Multi-tenancy is disabled below, so everything is written under Mimir's
// no-auth tenant (auth.no-auth-tenant default, "anonymous").
local rulerRulesTenant = 'anonymous';
// Distinct from the ruler's own scratch directory (ruler.rule-path, /rules)
// where it materializes rule groups pulled from this directory, and from
// /etc/mimir (the "overrides" ConfigMap mount) so this volume doesn't nest
// inside another ConfigMap's mount path.
local rulerRulesDir = '/etc/mimir-rules';

local rulerRulesConfigMap =
  configMap.new('mimir-recording-rules')
  + configMap.withDataMixin({
    'mimir-mixin.yaml': std.manifestYamlDoc({ groups: mimirMixinRecordingRules.prometheusRules.groups }),
  });

// withScrapeAnnotations adds prometheus.io/scrape annotations to a pod
// template so Alloy's annotation-based pod discovery (see
// argo/apps/monitoring/values.yaml) picks up the component's own /metrics
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

mimir {
  _config+:: {
    namespace: $._namespace,
    cluster: $._cluster,
    external_url: 'http://query-frontend.%s.svc.cluster.local' % $._namespace,

    aws_region: 'us-east-1', # unused
    storage_backend: 's3',
    storage_s3_endpoint: 'seaweedfs-s3.%s.svc.cluster.local:8333' % $._namespace,
    # Must match the S3 gateway admin identity configured in
    # argo/apps/metrics/seaweedfs.values.yaml (filer.s3.enableAuth / s3.credentials).
    # Also must be non-empty to stop the AWS SDK from falling back to the EC2
    # instance metadata service (169.254.169.254), which would hang and time
    # out in this homelab (no cloud metadata endpoint).
    storage_s3_access_key_id: 'mimir',
    storage_s3_secret_access_key: 'mimir',
    blocks_storage_bucket_name: 'mimir',
    # Drop replication factor to 1 as we don't run that many ingesters
    replication_factor: 1,
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

    # Enable the ruler so the mixin's recording rules (which the mixin
    # dashboards query) actually get evaluated. Rule groups are loaded from
    # a ConfigMap-backed local directory (see rulerRulesConfigMap below)
    # rather than the S3 backend, so there's no need for a mimirtool/CI job
    # to push them -- they're just part of the GitOps sync.
    ruler_enabled: true,
    ruler_storage_backend: 'local',
    ruler_local_directory: rulerRulesDir,

    # Scale down to 1 replica for the homelab setup.
    memcached_frontend_replicas: 1,
    memcached_index_queries_replicas: 1,
    memcached_chunks_replicas: 1,
    memcached_metadata_replicas: 1,
    memcached_range_vector_splitting_replicas: 1,

    # We are running the seeweedfs locally so there is no need to use TLS for the S3 endpoint.
    storageConfig+:: {
      'common.storage.s3.insecure': true,
    },

    # Disable multi-tenancy for the homelab setup.
    commonConfig+:: {
      'auth.multitenancy-enabled': false,
    },
  },

  

  compactor_statefulset+: statefulSet.mixin.spec.withReplicas(1),
  distributor_deployment+: deployment.mixin.spec.withReplicas(1),
  ingester_statefulset+: statefulSet.mixin.spec.withReplicas(1),
  querier_deployment+: deployment.mixin.spec.withReplicas(1),
  query_frontend_deployment+: deployment.mixin.spec.withReplicas(1),
  store_gateway_statefulset+: statefulSet.mixin.spec.withReplicas(1),
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
    + { spec+: {
        strategy+: { rollingUpdate: null },
        template+: { spec+: { affinity: null } } }
      },

  compactor_container+: k.util.resourcesRequests('100m', '128Mi'),
  distributor_container+: k.util.resourcesRequests('100m', '128Mi'),
  ingester_container+: k.util.resourcesRequests('100m', '128Mi'),
  querier_container+: k.util.resourcesRequests('100m', '128Mi'),
  query_frontend_container+: k.util.resourcesRequests('100m', '128Mi'),
  store_gateway_container+: k.util.resourcesRequests('100m', '128Mi'),

  ruler_deployment+:
    deployment.mixin.spec.withReplicas(1)
    + k.util.configMapVolumeMount(rulerRulesConfigMap, rulerRulesDir + '/' + rulerRulesTenant),
  ruler_container+: k.util.resourcesRequests('100m', '128Mi'),
}
# Let Alloy scrape each Mimir component's own /metrics via pod annotations,
# so Mimir's self-monitoring metrics end up in Mimir (see withScrapeAnnotations above).
+ {
  compactor_statefulset+: withScrapeAnnotations,
  distributor_deployment+: withScrapeAnnotations,
  ingester_statefulset+: withScrapeAnnotations,
  querier_deployment+: withScrapeAnnotations,
  query_frontend_deployment+: withScrapeAnnotations,
  query_scheduler_deployment+: withScrapeAnnotations,
  store_gateway_statefulset+: withScrapeAnnotations,
  ruler_deployment+: withScrapeAnnotations,
}
# With the tiny setup in the homelab, podDisruptionBudget is causing issues with syncing.
# Remove them for now and revisit in the future IF there are more nodes.
+ {
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

# Adjust the sync-wave so that mimir resources are created after the storage layer
+ {
  distributor_deployment+: withSyncWave(1),
  distributor_service+: withSyncWave(1),

  ingester_statefulset+: withSyncWave(1),
  ingester_service+: withSyncWave(1),

  querier_deployment+: withSyncWave(1),
  querier_service+: withSyncWave(1),

  query_frontend_deployment+: withSyncWave(1),
  query_frontend_service+: withSyncWave(1),

  query_scheduler_deployment+: withSyncWave(1),
  query_scheduler_service+: withSyncWave(1),
  query_scheduler_discovery_service+: withSyncWave(1),

  compactor_statefulset+: withSyncWave(1),
  compactor_service+: withSyncWave(1),

  store_gateway_statefulset+: withSyncWave(1),
  store_gateway_service+: withSyncWave(1),

  ruler_deployment+: withSyncWave(1),
  ruler_service+: withSyncWave(1),
}

# The mixin recording rules ConfigMap mounted into the ruler (see
# rulerRulesConfigMap above). Namespace comes from Tanka's environment
# default (spec.json), same as every other resource in this app. Give it the
# same sync-wave as the rest of the Mimir resources so it lands before the
# ruler tries to mount it.
+ {
  mimir_recording_rules_configmap:
    rulerRulesConfigMap
    + withSyncWave(1),
}

# Default values for the Tanka overrides. These can be overridden by the ArgoCD application.
+ {
  # Safe assumption, but should be passed in from the ArgoCD application.
  _namespace:: 'metrics-system',
  _cluster:: 'unknown',
}
