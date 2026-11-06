// The Pocket ID server. The operator creates its Deployment, Service and PVC from this.
{
  // No generated library for the CRDs, so a plain object.
  instance: {
    apiVersion: 'pocketid.internal/v1alpha1',
    kind: 'PocketIDInstance',
    metadata: { name: $._config.instanceName, namespace: $._config.namespace },
    spec: {
      appUrl: 'https://%s' % $._config.host,
      encryptionKey: { valueFrom: { secretKeyRef: { name: $.encryptionKey.spec.target.name, key: 'encryptionKey' } } },
      // The operator names the PVC after the instance, so keep the instance name and these settings as they are.
      persistence: { enabled: true, size: '1Gi' },
      // Cloudflare tunnel sets the real client IP in this header.
      env: [{ name: 'TRUSTED_PLATFORM', value: 'CF-Connecting-IP' }],
      // Traffic arrives via the in-cluster cloudflared pod, so only trust private ranges.
      trustedProxies: {
        enabled: true,
        cidrs: ['10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16', '100.64.0.0/10', '127.0.0.1/32', '::1/128', 'fd00::/8'],
      },
    },
  },
}
