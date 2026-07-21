local grafana = import 'github.com/grafana/jsonnet-libs/grafana/main.libsonnet';
local k = import 'k.libsonnet';
local k8s = import 'github.com/jsonnet-libs/k8s-libsonnet/1.35/main.libsonnet';

local container = k.core.v1.container;
local volume = k.core.v1.volume;
local volumeMount = k.core.v1.volumeMount;
local httpRoute = k8s.networking['networking.k8s.io/v1'].httpRoute;

local mixins = import 'mixins.libsonnet';

local withSyncWave(wave) = {
  metadata+: { annotations+: { 'argocd.argoproj.io/sync-wave': std.toString(wave) } },
};

grafana {
  _config+:: {
    # Dogfooding my own feature!
    configmap_binpack: true,
  }

  grafana_container+::
    container.withEnv([
      { name: 'GF_AUTH_GENERIC_OAUTH_CLIENT_ID', valueFrom: { secretKeyRef: { name: 'grafana-cloud', key: 'oauth-client-id' } } },
      { name: 'GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET', valueFrom: { secretKeyRef: { name: 'grafana-cloud', key: 'oauth-client-secret' } } },
    ]),
    + container.withPorts(k.core.v1.containerPort.new('grafana-metrics', 3000))
    + container.withVolumeMounts([
      volumeMount.new('grafana-data', '/var/lib/grafana', false),
      volumeMount.new('grafana-dashboards-sidecar', '/var/lib/grafana/dashboards/default', false),
    ]),

  grafana_deployment+:
    k.apps.v1.deployment.mixin.spec.template.spec.withContainers([
      $.grafana_container,
      container.new('dashboard-sidecar', 'ghcr.io/grafana/k8s-sidecar:latest')
      + container.withPorts(k.core.v1.containerPort.new('sidecar', 8080))
      + container.withEnv([
        { name: 'LABEL', value: 'grafana_dashboard' },
        { name: 'LABEL_VALUE', value: 'true' },
        { name: 'FOLDER', value: '/var/lib/grafana/dashboards/default' },
        { name: 'RESOURCE', value: 'configmap' },
        { name: 'WATCH_SERVER_URL', value: '' },
      ])
      + container.withVolumeMounts([
        volumeMount.new('grafana-dashboards-sidecar', '/var/lib/grafana/dashboards/default', false),
      ])
      + k.util.resourcesRequests('10m', '40Mi'),
    ])
    + k.apps.v1.deployment.mixin.spec.template.spec.withVolumesMixin([
      volume.fromPersistentVolumeClaim('grafana-data', 'grafana-data'),
      volume.emptyDir.new('grafana-dashboards-sidecar'),
    ])
    + withSyncWave(0),

  grafana_dashboard_provisioning_config_map+:
    k.core.v1.configMap.withData({
      'dashboards.yml': k.util.manifestYaml({
        apiVersion: 1,
        providers: [
          {
            name: 'default',
            orgId: 1,
            folder: '',
            type: 'file',
            disableDeletion: true,
            editable: false,
            options: {
              path: '/var/lib/grafana/dashboards/default',
            },
          },
        ],
      }),
    }),

  grafana_data_pvc:
    k.core.v1.persistentVolumeClaim.new('grafana-data')
    + k.core.v1.persistentVolumeClaim.mixin.spec.withAccessModes(['ReadWriteOnce'])
    + k.core.v1.persistentVolumeClaim.mixin.spec.resources.withRequests({ storage: '1Gi' })
    + withSyncWave(1),

  grafana_http_route:
    httpRoute.new('grafana')
    + httpRoute.mixin.metadata.withNamespace($.namespace)
    + httpRoute.mixin.spec.withParentRefs([{
      kind: 'Gateway',
      namespace: 'envoy-gateway-system',
      name: 'exposed',
    }])
    + httpRoute.mixin.spec.withHostnames(['grafana.%s' % $.domain])
    + httpRoute.mixin.spec.withRules([
      httpRoute.mixin.spec.rules[0]
      + httpRoute.mixin.spec.rules[0].withBackendRefs([
        httpRoute.mixin.spec.rules[0].backendRefs[0]
        + httpRoute.mixin.spec.rules[0].backendRefs[0].withPort(80),
      ]),
    ])
    + withSyncWave(1),
}
+ grafana.withRootUrl('https://grafana.%s/' % $.domain)
+ grafana.withGrafanaIniConfig({
  sections+: {
    auth+: {
      disable_login_form: false,
    },
    'auth.generic_oauth'+: {
      enabled: true,
      name: 'Dex',
      scopes: 'openid email profile groups offline_access',
      skip_org_role_sync: true,
      allow_sign_up: false,
      oauth_allow_insecure_email_lookup: true,
      auth_url: 'https://login.%s/auth' % $.domain,
      token_url: 'https://login.%s/token' % $.domain,
      api_url: 'https://login.%s/userinfo' % $.domain,
    },
  },
})
+ grafana.addDatasource('metrics', grafana.datasource.new(
  'Metrics',
  'http://query-frontend.%s.svc.cluster.local:8080/prometheus' % $.metricsNamespace,
  type='prometheus',
  default=true,
))
+ grafana.addMixinDashboards(mixins)

// Tanka override defaults (visible fields so std.toString in tanka.libsonnet
// serializes them into TANKA_OVERRIDES — hidden fields would be stripped)
+ {
  namespace:: 'monitoring',
  cluster:: 'unknown',
  domain:: 'REPLACE_ME',
  metricsNamespace:: 'metrics-system',
}
