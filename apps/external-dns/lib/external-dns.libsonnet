local tanka = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local helm = tanka.helm.new(std.thisFile);

{
  _namespace:: std.extVar('tanka.dev/environment').spec.namespace,

  externalDns: helm.template('external-dns', '../charts/external-dns', {
    namespace: $._namespace,
    values: {
      provider: { name: 'cloudflare' },
      policy: 'sync',
      sources: ['service', 'ingress', 'gateway-httproute'],
      env: [
        { name: 'CF_API_TOKEN', valueFrom: { secretKeyRef: { name: 'cloudflare-secret', key: 'token' } } },
      ],
      extraArgs: ['--annotation-filter=dns.kubernetes.io/exclude notin (true)'],
    },
  }),
}
