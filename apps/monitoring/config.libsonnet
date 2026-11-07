{
  _config+:: {
    // Also holds what Argo CD created before the move to Flux.
    namespace: 'monitoring',
    // Name of the cluster, attached to everything Alloy ships. Set per cluster.
    cluster: '',
    // Base domain of the cluster; Grafana is served at grafana.<domain> and Alloy at alloy.<domain>. Set per cluster.
    domain: '',
    // Gateway Grafana (exposed) and Alloy (internal) attach to; the name differs.
    gateway: { namespace: 'gateway-system' },
    // Mimir's query frontend, the default Grafana datasource.
    metricsUrl: 'http://query-frontend.metrics-system.svc.cluster.local:8080/prometheus',
    // Pocket ID, the login to Grafana.
    oidcIssuer: 'https://login.bednarzak.com',
    // Pocket ID user group (a PocketIDUserGroup in the pocketid namespace) allowed to log in to Grafana.
    allowedGroup: 'infra',
  },
}
