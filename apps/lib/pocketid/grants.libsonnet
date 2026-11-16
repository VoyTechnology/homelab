// Apps whose Envoy Gateway OIDC login calls the token endpoint of Pocket ID in-cluster (Cloudflare in front
// requires TLS 1.3, which Envoy's upstream does not offer). Cross-namespace references need a grant.
{
  local clients = ['longhorn-system'],

  grants: {
    apiVersion: 'gateway.networking.k8s.io/v1beta1',
    kind: 'ReferenceGrant',
    metadata: { name: 'oidc-token-endpoint', namespace: $._config.namespace },
    spec: {
      from: [{ group: 'gateway.envoyproxy.io', kind: 'SecurityPolicy', namespace: ns } for ns in clients],
      to: [{ group: '', kind: 'Service', name: $._config.instanceName }],
    },
  },
}
