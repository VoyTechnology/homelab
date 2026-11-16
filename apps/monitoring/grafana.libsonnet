local grafana = import 'github.com/grafana/jsonnet-libs/grafana/grafana.libsonnet';
local k = import 'k.libsonnet';
local util = import 'ksonnet-util/util.libsonnet';

local container = k.core.v1.container;
local volume = k.core.v1.volume;
local volumeMount = k.core.v1.volumeMount;

{
  // Alloy scrapes every 1m; without timeInterval Grafana assumes 15s and computes too narrow a $__rate_interval.
  // Grafana only updates an already provisioned datasource when its version is higher than the stored one (the
  // library's default of 1 is below it), so bump the version whenever the datasource changes.
  metricsDatasource::
    grafana.datasource.new('Metrics', $._config.metricsUrl, type='prometheus', default=true)
    + grafana.datasource.withJsonData({ timeInterval: '1m' })
    + { version: 3 },

  grafana: grafana
           + grafana.withRootUrl('https://%s/' % $._config.grafanaHost)
           + grafana.withGrafanaIniConfig($.grafana.iniConfig)
           + grafana.addDatasource('metrics', $.metricsDatasource)
           + grafana.addMixinDashboards(import 'mixins.libsonnet')
           + {
             _config+:: { configmap_binpack: true },

             // Use withEnvMixin (not withEnv) elsewhere: withEnv drops GF_PATHS_CONFIG and the config is then ignored.
             grafana_container+::
               container.withPorts(
                 k.core.v1.containerPort.withName('grafana-metrics')
                 + k.core.v1.containerPort.withContainerPort(3000),
               )
               + container.withVolumeMounts([volumeMount.new('grafana-data', '/var/lib/grafana', false)]),

             // The mixins own the dashboard list: the library's disableDeletion keeps a dashboard in Grafana's
             // database after its file disappears, so a removed mixin dashboard would linger forever.
             dashboard_provisioning_config_map+: {
               data+: {
                 'dashboards.yml':
                   local providers = std.parseYaml(super['dashboards.yml']);
                   util.manifestYaml(providers { providers: [p { disableDeletion: false } for p in providers.providers] }),
               },
             },

             grafana_data_pvc:
               k.core.v1.persistentVolumeClaim.new('grafana-data')
               + k.core.v1.persistentVolumeClaim.mixin.spec.withAccessModes(['ReadWriteOnce'])
               + k.core.v1.persistentVolumeClaim.mixin.spec.resources.withRequests({ storage: '1Gi' }),

             // uid 472 cannot write a fresh root-owned volume. Recreate: Grafana locks its search index in the
             // RWO volume, so a rolling update leaves the new pod crashlooping on the lock.
             grafana_deployment+:
               k.apps.v1.deployment.mixin.spec.template.spec.withVolumesMixin([
                 volume.fromPersistentVolumeClaim('grafana-data', 'grafana-data'),
               ])
               + k.apps.v1.deployment.mixin.spec.template.spec.securityContext.withFsGroup(472)
               + k.apps.v1.deployment.mixin.spec.strategy.withType('Recreate')
               + { spec+: { strategy+: { rollingUpdate: null } } },
           },
}
