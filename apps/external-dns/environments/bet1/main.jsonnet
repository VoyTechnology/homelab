// Tanka environment for the bet1 cluster. The namespace comes from spec.json
// (external-dns-system, created by Ansible).
(import 'external-dns/main.libsonnet')
+ {
  _config+:: {
    namespace: std.extVar('tanka.dev/environment').spec.namespace,
    sources: ['service', 'ingress', 'gateway-httproute'],
    annotationFilter: 'dns.kubernetes.io/exclude notin (true)',
    env: [
      { name: 'CF_API_TOKEN', valueFrom: { secretKeyRef: { name: 'cloudflare-secret', key: 'token' } } },
    ],
  },
}
