// Scaling: replica counts and CPU/memory requests and limits.
local container = (import 'k.libsonnet').core.v1.container;

{
  grafana+: {
    // Sits at ~280Mi idle but the Mimir dashboards (dozens of panels) pushed it past 512Mi and got it OOMKilled;
    // unlimited it can take the whole node.
    grafana_container+:: container.resources.withLimits({ memory: '1Gi' }),
  },
}
