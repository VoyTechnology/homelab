// Pinned here, not in the libraries, so Renovate can bump them.
{
  _images+:: {
    // renovate: datasource=docker depName=docker.io/grafana/alloy
    alloy: 'docker.io/grafana/alloy:v1.18.1',
    // renovate: datasource=docker depName=quay.io/prometheus-operator/prometheus-config-reloader
    configReloader: 'quay.io/prometheus-operator/prometheus-config-reloader:v0.91.0',
    // renovate: datasource=docker depName=registry.k8s.io/kube-state-metrics/kube-state-metrics
    kubeStateMetrics: 'registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.15.0',
    // renovate: datasource=docker depName=quay.io/prometheus/node-exporter
    nodeExporter: 'quay.io/prometheus/node-exporter:v1.11.1',
  },

  // The Grafana library defaults to an image from 2021.
  grafana+: {
    _images+:: {
      // renovate: datasource=docker depName=grafana/grafana
      grafana: 'grafana/grafana:13.1.3',
    },
  },
}
