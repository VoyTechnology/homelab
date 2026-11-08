{
  _config+:: {
    // Also holds what Argo CD created before the move to Flux.
    namespace: 'metrics-system',
    // Name of the cluster, attached to the Mimir config. Set per cluster.
    cluster: '',
    external_url: 'http://query-frontend.%s.svc.cluster.local' % self.namespace,

    // Garage, the S3 store behind Mimir. Mimir reaches it at `<name>.<namespace>:3900`.
    buckets: ['mimir'],
    storageClassName: 'longhorn-single',
    metaSize: '1Gi',
    dataSize: '20Gi',
    layoutCapacity: 20 * 1000 * 1000 * 1000,
    resources: { requests: { cpu: '50m', memory: '128Mi' }, limits: { memory: '512Mi' } },

    aws_region: self.region,  // unused, the endpoint below is set explicitly
    storage_backend: 's3',
    storage_s3_endpoint: '%s.%s.svc.cluster.local:3900' % [self.name, self.namespace],
    // Set on the components from the S3 key Secret (see mimir.libsonnet); the kubelet expands $(VAR) in args.
    storage_s3_access_key_id: '$(S3_ACCESS_KEY_ID)',
    storage_s3_secret_access_key: '$(S3_SECRET_ACCESS_KEY)',
    blocks_storage_bucket_name: 'mimir',

    // Drop replication factor to 1 as we don't run that many ingesters
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

    // Enable the ruler so the mixin's recording rules (which the mixin
    // dashboards query) actually get evaluated. Rule groups are loaded from
    // a ConfigMap-backed local directory (see rules.libsonnet) rather than
    // the S3 backend, so there's no need for a mimirtool/CI job to push them.
    ruler_enabled: true,
    ruler_storage_backend: 'local',

    // Scale down to 1 replica for the homelab setup.
    memcached_frontend_replicas: 1,
    memcached_index_queries_replicas: 1,
    memcached_chunks_replicas: 1,
    memcached_metadata_replicas: 1,
    memcached_range_vector_splitting_replicas: 1,

    // Garage runs in the cluster, so there is no TLS on the S3 endpoint, and it only does path-style buckets.
    storageConfig+:: {
      'common.storage.s3.insecure': true,
      'common.storage.s3.region': $._config.region,
      'common.storage.s3.bucket-lookup-type': 'path',
    },

    // Disable multi-tenancy for the homelab setup.
    commonConfig+:: {
      'auth.multitenancy-enabled': false,
    },

    // Bump the per-tenant series budget from the extra_small_user default
    // (150k) to the medium_small_user tier's series/metadata caps (300k),
    // layered on top of extra_small_user rather than switching tiers
    // outright -- medium_small_user has no compactor_blocks_retention_period,
    // which compactor.libsonnet requires unconditionally, so a bare
    // `overrides.medium_small_user` breaks compactor rendering.
    //
    // We hit the 150k ceiling exactly once the kubelet/cadvisor scrape fix
    // (see apps/monitoring alloy-config.alloy history) started actually
    // ingesting data for the first time -- the distributor then rejects any
    // push containing series it hasn't seen before, cluster-wide, which
    // silently blocks onboarding anything new (e.g. homeassistant's
    // ServiceMonitor). alloy-config.alloy also trims the biggest offender
    // (k3s's kubelet endpoint leaking apiserver/etcd/scheduler control-plane
    // metrics), but bump the ceiling too so there's real headroom instead of
    // living right at 150k again.
    limits: $._config.overrides.extra_small_user {
      max_global_series_per_user: 300000,
      max_global_metadata_per_user: std.ceil(self.max_global_series_per_user * 0.2),
      // Blocks older than this are deleted, which also bounds the 20Gi Garage volume.
      compactor_blocks_retention_period: '7d',
    },
  },
}
