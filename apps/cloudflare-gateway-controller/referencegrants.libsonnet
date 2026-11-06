// The GatewayClass reads its credentials from this namespace, so Gateways in other namespaces need
// a grant. No generated library for the Gateway API, so plain objects.
{
  referenceGrants: {
    [ns]: {
      apiVersion: 'gateway.networking.k8s.io/v1beta1',
      kind: 'ReferenceGrant',
      metadata: { name: 'cloudflare-gateway-credentials-' + ns, namespace: $._config.namespace },
      spec: {
        from: [{ group: 'gateway.networking.k8s.io', kind: 'Gateway', namespace: ns }],
        to: [{ group: '', kind: 'Secret', name: $.cloudflareSecret.spec.target.name }],
      },
    }
    for ns in $._config.gatewayNamespaces
  },
}
