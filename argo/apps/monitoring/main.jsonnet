local grafana = import 'grafana.libsonnet';
local alloy = import 'alloy.libsonnet';
local kubeStateMetrics = import 'kube-state-metrics.libsonnet';
local nodeExporter = import 'node-exporter.libsonnet';
local grafanaCloud = import 'grafana-cloud.libsonnet';

grafana + alloy + kubeStateMetrics + nodeExporter + grafanaCloud
