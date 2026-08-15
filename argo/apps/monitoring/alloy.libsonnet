// Grafana Alloy: scrapes/collects metrics and logs and ships them to
// Grafana Cloud and the local Mimir. Deployment, not DaemonSet or
// StatefulSet -- clustering is disabled (alloy.clustering.enabled = false
// in alloy-config.alloy) and there's no per-pod persistent state, so a
// single stable identity per replica isn't needed.
//
// RBAC/Deployment/Service shape below mirrors the grafana/alloy Helm
// chart's default rendering (verified against chart version 1.11.1 via
// `helm template`) so discovery.kubernetes and
// prometheus.operator.servicemonitors keep working unchanged.
local config = import 'config.libsonnet';
local k = import 'k.libsonnet';

local container = k.core.v1.container;
local containerPort = k.core.v1.containerPort;
local volume = k.core.v1.volume;
local volumeMount = k.core.v1.volumeMount;
local configMap = k.core.v1.configMap;
local service = k.core.v1.service;
local servicePort = k.core.v1.servicePort;
local serviceAccount = k.core.v1.serviceAccount;
local clusterRole = k.rbac.v1.clusterRole;
local clusterRoleBinding = k.rbac.v1.clusterRoleBinding;
local subject = k.rbac.v1.subject;
local deployment = k.apps.v1.deployment;

config + {
  local this = self,

  alloy_service_account: serviceAccount.new('alloy'),

  alloy_cluster_role:
    clusterRole.new('alloy')
    + clusterRole.withRules([
      { apiGroups: ['', 'discovery.k8s.io', 'networking.k8s.io'], resources: ['endpoints', 'endpointslices', 'ingresses', 'pods', 'services'], verbs: ['get', 'list', 'watch'] },
      { apiGroups: [''], resources: ['pods', 'pods/log', 'namespaces'], verbs: ['get', 'list', 'watch'] },
      { apiGroups: ['monitoring.grafana.com'], resources: ['podlogs'], verbs: ['get', 'list', 'watch'] },
      { apiGroups: ['monitoring.coreos.com'], resources: ['prometheusrules'], verbs: ['get', 'list', 'watch'] },
      { apiGroups: ['monitoring.coreos.com'], resources: ['alertmanagerconfigs'], verbs: ['get', 'list', 'watch'] },
      { apiGroups: ['monitoring.coreos.com'], resources: ['podmonitors', 'servicemonitors', 'probes', 'scrapeconfigs'], verbs: ['get', 'list', 'watch'] },
      { apiGroups: [''], resources: ['events'], verbs: ['get', 'list', 'watch'] },
      { apiGroups: [''], resources: ['configmaps', 'secrets'], verbs: ['get', 'list', 'watch'] },
      { apiGroups: ['apps', 'extensions'], resources: ['replicasets'], verbs: ['get', 'list', 'watch'] },
      // Node discovery/scraping for the kubelet and cadvisor targets in
      // alloy-config.alloy.
      { apiGroups: [''], resources: ['nodes'], verbs: ['get', 'list', 'watch'] },
      { apiGroups: [''], resources: ['nodes/pods'], verbs: ['get', 'list', 'watch'] },
      { apiGroups: [''], resources: ['nodes/metrics'], verbs: ['get', 'list', 'watch'] },
      { nonResourceURLs: ['/metrics'], verbs: ['get'] },
    ]),

  alloy_cluster_role_binding:
    clusterRoleBinding.new('alloy')
    + clusterRoleBinding.bindRole(this.alloy_cluster_role)
    + clusterRoleBinding.withSubjects([
      subject.withKind('ServiceAccount')
      + subject.withName('alloy')
      + subject.withNamespace(this.namespace),
    ]),

  // Renovate's jsonnet custom manager only tracks `targetRevision = '...'`
  // assignments, not image tags, so these aren't auto-bumped -- check
  // https://github.com/grafana/alloy/releases and
  // https://github.com/prometheus-operator/prometheus-operator/releases
  // (config-reloader) occasionally and bump by hand.
  _images:: {
    alloy: 'docker.io/grafana/alloy:v1.18.1',
    config_reloader: 'quay.io/prometheus-operator/prometheus-config-reloader:v0.91.0',
  },

  alloy_config_map:
    configMap.new('alloy-config', { 'config.alloy': importstr 'alloy-config.alloy' }),

  alloy_container::
    container.new('alloy', this._images.alloy)
    + container.withArgs([
      'run',
      '/etc/alloy/config.alloy',
      '--storage.path=/tmp/alloy',
      '--server.http.listen-addr=0.0.0.0:12345',
      '--server.http.ui-path-prefix=/',
      // Matches alloy.alloy.stabilityLevel from the previous Helm values.
      '--stability.level=experimental',
    ])
    + container.withEnv([
      { name: 'CLUSTER_NAME', value: this.cluster },
      { name: 'GRAFANA_USER', valueFrom: { secretKeyRef: { name: 'grafana-cloud', key: 'user' } } },
      { name: 'LOKI_URL', valueFrom: { secretKeyRef: { name: 'grafana-cloud', key: 'logs-url' } } },
      { name: 'LOKI_USER', valueFrom: { secretKeyRef: { name: 'grafana-cloud', key: 'loki-user' } } },
      { name: 'PROMETHEUS_URL', valueFrom: { secretKeyRef: { name: 'grafana-cloud', key: 'metrics-url' } } },
      { name: 'REMOTE_CONFIG_URL', valueFrom: { secretKeyRef: { name: 'grafana-cloud', key: 'remote-config-url' } } },
      { name: 'TOKEN', valueFrom: { secretKeyRef: { name: 'grafana-cloud', key: 'token' } } },
    ])
    + container.withPorts([
      containerPort.newNamed(name='http-metrics', containerPort=12345),
    ])
    + container.readinessProbe.httpGet.withPath('/-/ready')
    + container.readinessProbe.httpGet.withPort(12345)
    + container.readinessProbe.withInitialDelaySeconds(10)
    + container.readinessProbe.withTimeoutSeconds(1)
    + container.withVolumeMounts([
      volumeMount.new('config', '/etc/alloy', false),
    ]),

  // Watches the config ConfigMap and hits Alloy's /-/reload endpoint on
  // change, so config edits (alloy-config.alloy) don't require a pod
  // restart -- same as the Helm chart's default configReloader.
  alloy_config_reloader_container::
    container.new('config-reloader', this._images.config_reloader)
    + container.withArgs([
      '--watched-dir=/etc/alloy',
      '--reload-url=http://localhost:12345/-/reload',
    ])
    + container.withVolumeMounts([
      volumeMount.new('config', '/etc/alloy', false),
    ])
    + container.resources.withRequests({ cpu: '10m', memory: '50Mi' })
    + container.securityContext.withAllowPrivilegeEscalation(false)
    + container.securityContext.withReadOnlyRootFilesystem(true)
    + container.securityContext.withRunAsNonRoot(true)
    + container.securityContext.withRunAsUser(65534)
    + container.securityContext.withRunAsGroup(65534)
    + container.securityContext.capabilities.withDrop(['ALL']),

  alloy_deployment:
    deployment.new('alloy', 1, [
      this.alloy_container,
      this.alloy_config_reloader_container,
    ])
    + deployment.spec.template.spec.withServiceAccountName('alloy')
    + deployment.spec.template.spec.withVolumes([
      volume.fromConfigMap('config', 'alloy-config'),
    ]),

  alloy_service:
    service.new(
      'alloy',
      this.alloy_deployment.spec.template.metadata.labels,
      [servicePort.newNamed('http-metrics', 12345, 12345)],
    ),

  // Alloy's UI, via the Gateway API "internal" Gateway (LAN-only, not
  // internet-exposed) instead of the internal-login Ingress class. Note
  // this is a real change, not just a mechanical port: internal-login
  // fronted the UI with an oauth2-proxy login gate (see
  // ansible/playbooks/roles/k3s/services/tasks/ingress/internal_login.yml);
  // the "internal" Gateway has no equivalent auth gate wired up yet, so
  // this trades "LAN + login" for "LAN only". Same pattern as
  // grafana.libsonnet's httpRoute, which uses the "exposed" Gateway
  // instead. The previous Helm values also punched an extra /faro path
  // through to a port (12347) that no container or receiver in
  // alloy-config.alloy ever exposed -- dropped as dead config rather than
  // carried forward.
  alloy_http_route: {
    apiVersion: 'gateway.networking.k8s.io/v1',
    kind: 'HTTPRoute',
    metadata: {
      name: 'alloy',
      namespace: this.namespace,
    },
    spec: {
      parentRefs: [{
        kind: 'Gateway',
        namespace: 'envoy-gateway-system',
        name: 'internal',
      }],
      hostnames: ['alloy.%s' % this.domain],
      rules: [{
        backendRefs: [{
          name: 'alloy',
          port: 12345,
        }],
      }],
    },
  },
}
