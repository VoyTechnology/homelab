local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.35/main.libsonnet';

local networkPolicy = k.networking.v1.networkPolicy;

// The chart's `longhorn-manager` NetworkPolicy only admits Longhorn's own pods, so Alloy
// (monitoring namespace) is refused when it scrapes the manager's /metrics. Policies add up.
{
  allowMetricsScrape:
    networkPolicy.new('longhorn-manager-allow-metrics')
    + networkPolicy.spec.podSelector.withMatchLabels({ app: 'longhorn-manager' })
    + networkPolicy.spec.withPolicyTypes(['Ingress'])
    + networkPolicy.spec.withIngress([{
      from: [{
        namespaceSelector: { matchLabels: { 'kubernetes.io/metadata.name': 'monitoring' } },
        podSelector: { matchLabels: { name: 'alloy' } },
      }],
      ports: [{ port: 9500, protocol: 'TCP' }],
    }]),
}
