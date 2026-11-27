// Scaling: replica counts and CPU/memory requests and limits.
local container = (import 'k.libsonnet').core.v1.container;

{
  grafana+: {
    // Was sitting at its old 1Gi limit (resident ~960Mi) and restarting (OOMKilled), so the real
    // need is unknown: it is 280Mi idle, and the Mimir dashboards (dozens of panels) push it up.
    // Unlimited it can take the whole node. Re-check usage after this lands.
    grafana_container+::
      container.resources.withRequests({ cpu: '100m', memory: '1Gi' })
      + container.resources.withLimits({ memory: '2Gi' }),
  },

  // Resident ~140Mi, which left almost no headroom under the old 150Mi limit.
  kube_state_metrics_deployment+: { spec+: { template+: { spec+: { containers: [
    c { resources: { requests: { cpu: '10m', memory: '192Mi' }, limits: { memory: '384Mi' } } }
    for c in super.containers
  ] } } } },

  // ~800Mi resident over 30 days.
  alloy_container+::
    container.resources.withRequests({ cpu: '50m', memory: '896Mi' })
    + container.resources.withLimits({ memory: '1536Mi' }),

  // ~25Mi.
  node_exporter_container+::
    container.resources.withRequests({ cpu: '10m', memory: '32Mi' })
    + container.resources.withLimits({ memory: '128Mi' }),
}
