// kube-state-metrics watches the Kubernetes API server and exposes cluster
// object state (kube_deployment_*, kube_statefulset_*, kube_pod_*, ...) as
// metrics. It's a single-replica Deployment, not a per-node DaemonSet --
// it reports on the whole cluster's state once, not per-node data, and
// running it as a DaemonSet would produce duplicate series for every
// object on every node. Sharding (--shard/--total-shards) exists for
// clusters with thousands of objects; this cluster doesn't need it.
local config = import 'config.libsonnet';
local ksm = import 'github.com/grafana/jsonnet-libs/kube-state-metrics/main.libsonnet';
local k = import 'k.libsonnet';

local service = k.core.v1.service;
local servicePort = k.core.v1.servicePort;

config + {
  local this = ksm.new(
    $.namespace,
    // Vendored lib defaults to kube-state-metrics v2.1.0 (2021). Renovate's
    // jsonnet custom manager only tracks `targetRevision = '...'`
    // assignments, not image tags, so this isn't auto-bumped -- check
    // https://github.com/kubernetes/kube-state-metrics/releases occasionally
    // and bump by hand.
    image='registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.15.0',
  ),

  kube_state_metrics_service_account: this.rbac.service_account,
  kube_state_metrics_cluster_role: this.rbac.cluster_role,
  kube_state_metrics_cluster_role_binding: this.rbac.cluster_role_binding,
  kube_state_metrics_deployment: this.deployment,

  // Named "kube-state-metrics" (a fixed, predictable DNS name), not the
  // Tanka-app-prefixed name, so alloy-config.alloy's static
  // prometheus.scrape target can address it directly.
  kube_state_metrics_service:
    service.new(
      'kube-state-metrics',
      this.deployment.spec.template.metadata.labels,
      [
        servicePort.newNamed('ksm', 8080, 8080),
        servicePort.newNamed('self-metrics', 8081, 8081),
      ],
    ),
}
