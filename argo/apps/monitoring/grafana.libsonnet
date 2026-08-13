local grafana = import 'github.com/grafana/jsonnet-libs/grafana/grafana.libsonnet';
local k = import 'k.libsonnet';

local container = k.core.v1.container;
local volume = k.core.v1.volume;
local volumeMount = k.core.v1.volumeMount;

local mixins = import 'mixins.libsonnet';

local withSyncWave(wave) = {
  metadata+: { annotations+: { 'argocd.argoproj.io/sync-wave': std.toString(wave) } },
};

// Tanka override defaults (visible fields so std.toString in tanka.libsonnet
// serializes them into TANKA_OVERRIDES — hidden fields would be stripped)
{
  namespace:: 'monitoring',
  cluster:: 'unknown',
  domain:: 'REPLACE_ME',
  metricsNamespace:: 'metrics-system',

  metricsDatasource::
    grafana.datasource.new(
      'Metrics',
      'http://query-frontend.%s.svc.cluster.local:8080/prometheus' % $.metricsNamespace,
      type='prometheus',
      default=true,
    ),

  iniConfig:: {
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
  },

  // Gateway API's HTTPRoute isn't a type k8s-libsonnet generates (it's a
  // CRD, not core Kubernetes), so this is a plain manifest object.
  httpRoute:: {
    apiVersion: 'gateway.networking.k8s.io/v1',
    kind: 'HTTPRoute',
    metadata: {
      name: 'grafana',
      namespace: $.namespace,
    },
    spec: {
      parentRefs: [{
        kind: 'Gateway',
        namespace: 'envoy-gateway-system',
        name: 'exposed',
      }],
      hostnames: ['grafana.%s' % $.domain],
      rules: [{
        backendRefs: [{
          name: 'grafana',
          port: 80,
        }],
      }],
    },
  } + withSyncWave(1),

  grafana: grafana
    + grafana.withRootUrl('https://grafana.%s/' % $.domain)
    + grafana.withGrafanaIniConfig($.iniConfig)
    + grafana.addDatasource('metrics', $.metricsDatasource)
    + grafana.addMixinDashboards(mixins)
    + {
      _config+:: {
        # Dogfooding my own feature!
        configmap_binpack: true,
      },

      grafana_container+::
        container.withEnv([
          { name: 'GF_AUTH_GENERIC_OAUTH_CLIENT_ID', valueFrom: { secretKeyRef: { name: 'grafana-cloud', key: 'oauth-client-id' } } },
          { name: 'GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET', valueFrom: { secretKeyRef: { name: 'grafana-cloud', key: 'oauth-client-secret' } } },
        ])
        + container.withPorts(
            k.core.v1.containerPort.withName('grafana-metrics')
            + k.core.v1.containerPort.withContainerPort(3000),
          )
        + container.withVolumeMounts([
            volumeMount.new('grafana-data', '/var/lib/grafana', false),
            volumeMount.new('grafana-dashboards-sidecar', '/var/lib/grafana/dashboards/default', false),
          ]),

      grafana_data_pvc:
        k.core.v1.persistentVolumeClaim.new('grafana-data')
        + k.core.v1.persistentVolumeClaim.mixin.spec.withAccessModes(['ReadWriteOnce'])
        + k.core.v1.persistentVolumeClaim.mixin.spec.resources.withRequests({ storage: '1Gi' })
        + withSyncWave(1),

      grafana_http_route: $.httpRoute,

      // grafana_deployment+:
      //   k.apps.v1.deployment.mixin.spec.template.spec.withContainers([
      //     $.grafana_container,
      //     $.dashboardSidecar,
      //   ])
      //   + k.apps.v1.deployment.mixin.spec.template.spec.withVolumesMixin([
      //     volume.fromPersistentVolumeClaim('grafana-data', 'grafana-data'),
      //     volume.emptyDir.new('grafana-dashboards-sidecar'),
      //   ])
      //   + withSyncWave(0),
    }
}
