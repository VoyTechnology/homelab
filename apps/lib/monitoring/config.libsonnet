{
  _config+:: {
    // Also holds what Argo CD created before the move to Flux.
    namespace: 'monitoring',
    // Name of the cluster, attached to everything Alloy ships. Set per cluster.
    cluster: '',
    // Base domain of the cluster; Alloy is served at alloy.<domain>. Set per cluster.
    domain: '',
    // Host of Grafana, which does not follow the cluster domain. Set per cluster.
    grafanaHost: '',
    // Mimir's query frontend, the default Grafana datasource.
    metricsUrl: 'http://query-frontend.metrics-system.svc.cluster.local:8080/prometheus',
    // UID of Grafana's Metrics datasource (Mimir), which the local alert rules query.
    metricsDatasourceUid: 'metrics',
    // UID of Grafana Cloud's hosted metrics datasource, which the Cloud alert rules query.
    cloudDatasourceUid: 'grafanacloud-prom',
    // Pocket ID, the login to Grafana.
    oidcIssuer: 'https://login.bednarzak.com',
  },
}
