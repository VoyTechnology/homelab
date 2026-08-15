local grafana = import 'grafana.libsonnet';
local alloy = import 'alloy.libsonnet';
local kubeStateMetrics = import 'kube-state-metrics.libsonnet';

grafana + alloy + kubeStateMetrics
