local grafana = import 'github.com/grafana/jsonnet-libs/grafana/grafana.libsonnet';
local k = import 'k.libsonnet';

local container = k.core.v1.container;
local volume = k.core.v1.volume;
local volumeMount = k.core.v1.volumeMount;

{
  grafana: grafana
           + grafana.withRootUrl('https://%s/' % $._config.grafanaHost)
           + grafana.withGrafanaIniConfig($.grafana.iniConfig)
           // Alloy scrapes every 1m; without this Grafana assumes 15s and computes too narrow a $__rate_interval.
           + grafana.addDatasource('metrics', grafana.datasource.new('Metrics', $._config.metricsUrl, type='prometheus', default=true) + grafana.datasource.withJsonData({ timeInterval: '1m' }))
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
