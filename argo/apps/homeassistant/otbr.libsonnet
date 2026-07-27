local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.35/main.libsonnet';

local sts = k.apps.v1.statefulSet;
local svc = k.core.v1.service;

{
    local this = self,

    container::
        k.core.v1.container.new('otbr', $._images.otbr)
        + k.core.v1.container.withEnvMap({
            DEVICE: $._config.threadDongle,
            BACKBONE_IF: $._config.networkInterface,
            BAUDRATE: '460800',
            FLOW_CONTROL: '0',
            FIREWALL: '1',
            NAT64: '1',
            AUTOFLASH_FIRMWARE: '0',
            OTBR_REST_PORT: '%d' % $._config.restPort,
            OTBR_WEB_PORT: '%d' % $._config.webPort,
        })
        + k.core.v1.container.withVolumeMounts([
            k.core.v1.volumeMount.new('thread-dongle', $._config.threadDongle),
            k.core.v1.volumeMount.new('tun', '/dev/net/tun'),
        ])
        + k.core.v1.container.mixin.securityContext.withPrivileged(true),

        dongleVolume:: k.core.v1.volume.fromHostPath('thread-dongle', $._config.threadDongle),
        tunVolume:: k.core.v1.volume.fromHostPath('tun', '/dev/net/tun'),

    statefulSet:
        sts.new('otbr', containers=[this.container], podLabels={ app: 'otbr' })
        + sts.mixin.spec.withReplicas(1)
        + sts.mixin.spec.template.spec.withVolumes([
            self.dongleVolume,
            self.tunVolume,
        ])
        + sts.mixin.spec.template.spec.withNodeSelector({ 'kubernetes.io/hostname': $._config.nodeName })
        + sts.mixin.spec.template.spec.withHostNetwork(true)
        + sts.mixin.spec.template.spec.withDnsPolicy('ClusterFirstWithHostNet'),

    service: svc.new('otbr', { app: 'otbr' }, [
        k.core.v1.servicePort.newNamed('rest-api', $._config.restPort, $._config.restPort),
        k.core.v1.servicePort.newNamed('web', $._config.webPort, $._config.webPort),
    ]),
}
