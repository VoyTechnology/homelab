// Reloads Home Assistant after the mixin ConfigMaps (automations, scripts, scenes, dashboards) change, so
// they apply without restarting it. Flux has no post-sync hook, and a Job is immutable, so the name carries a
// hash of the ConfigMaps: a change creates a new Job and pruning removes the old one. Do not set a TTL on it,
// Flux would create it again. Changes to configuration.yaml still roll the pod through the library's checksum.
{
  reloadHash:: std.substr(std.md5(std.manifestJsonEx($.homeassistant.haMixinConfigMaps, '')), 0, 8),

  reloadJob: {
    apiVersion: 'batch/v1',
    kind: 'Job',
    metadata: { name: 'homeassistant-reload-' + $.reloadHash, namespace: $._config.namespace },
    spec: {
      backoffLimit: 3,
      template: { spec: {
        restartPolicy: 'Never',
        containers: [{
          name: 'reload',
          image: $._images.curl,
          // Only the `token` key is used. The `url` key is the public address, which goes through the tunnel
          // and would fail whenever it is unavailable.
          envFrom: [{ secretRef: { name: $._config.tokenSecretName } }],
          command: ['sh', '-c'],
          args: [|||
            # The kubelet refreshes ConfigMap volumes about a minute after they change.
            sleep 90
            curl -fsS -X POST -H "Authorization: Bearer $token" "http://%s.%s.svc.cluster.local:%d/api/services/homeassistant/reload_all"
          ||| % [$.homeassistant.haService.metadata.name, $._config.namespace, $.homeassistant._config.port]],
        }],
      } },
    },
  },
}
