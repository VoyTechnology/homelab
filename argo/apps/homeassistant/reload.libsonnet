// Reloads Home Assistant after each sync so changes to the mixin ConfigMaps (automations,
// scripts, scenes, dashboards) apply without restarting it. Changes to configuration.yaml
// still roll the pod through the library's checksum annotation.
local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.35/main.libsonnet';

{
    haReloadJob:
        k.batch.v1.job.new('homeassistant-reload')
        + k.batch.v1.job.metadata.withNamespace('homeassistant')
        + k.batch.v1.job.metadata.withAnnotations({
            'argocd.argoproj.io/hook': 'PostSync',
            'argocd.argoproj.io/hook-delete-policy': 'BeforeHookCreation',
        })
        + k.batch.v1.job.spec.withBackoffLimit(3)
        + k.batch.v1.job.spec.template.spec.withRestartPolicy('Never')
        + k.batch.v1.job.spec.template.spec.withContainers([
            k.core.v1.container.new('reload', $._images.curl)
            // Only the `token` key is used, see homeassistant-matterhub in extra.values.yaml. The `url` key is
            // the public address, which goes through the tunnel and would fail whenever it is unavailable.
            + k.core.v1.container.withEnvFrom([{ secretRef: { name: 'homeassistant-matterhub' } }])
            + k.core.v1.container.withCommand(['sh', '-c'])
            + k.core.v1.container.withArgs([|||
                # The kubelet refreshes ConfigMap volumes about a minute after they change.
                sleep 90
                curl -fsS -X POST -H "Authorization: Bearer $token" "http://homeassistant.homeassistant.svc.cluster.local:%d/api/services/homeassistant/reload_all"
            ||| % [$._config.port]]),
        ]),
}
