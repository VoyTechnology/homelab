local cm = import 'github.com/jsonnet-libs/cert-manager-libsonnet/1.19/main.libsonnet';
local envoy = import 'github.com/jsonnet-libs/envoy-gateway-libsonnet/v1.7.1/main.libsonnet';
local certificate = cm.nogroup.v1.certificate;
local envoyProxy = envoy.gateway.v1alpha1.envoyProxy;

// Two gateways, each with its own Envoy proxy behind a MetalLB LoadBalancer and a wildcard certificate.
// `exposed` is port-forwarded from the router, `internal` is only reachable on the local network.
local gateway(cfg, name, address, annotations={}) = {
  local ns = cfg.namespace,
  local wildcard = '*.' + cfg.domain,
  local tlsSecret = name + '-wildcard-tls',

  proxy:
    envoyProxy.new('envoy-' + name)
    + envoyProxy.metadata.withNamespace(ns)
    + envoyProxy.spec.provider.withType('Kubernetes')
    + envoyProxy.spec.provider.kubernetes.envoyService.withType('LoadBalancer')
    + envoyProxy.spec.provider.kubernetes.envoyService.withAnnotations(
      { 'metallb.io/address-pool': cfg.addressPool }
      + (if address != '' then { 'metallb.io/loadBalancerIPs': address } else {})
    ),

  // No generated library for the Gateway API, so plain objects.
  class: {
    apiVersion: 'gateway.networking.k8s.io/v1',
    kind: 'GatewayClass',
    // Cluster-scoped, so keep Tanka from adding the environment's namespace.
    metadata: { name: 'envoy-' + name, annotations: { 'tanka.dev/namespaced': 'false' } },
    spec: {
      controllerName: 'gateway.envoyproxy.io/gatewayclass-controller',
      parametersRef: { group: 'gateway.envoyproxy.io', kind: 'EnvoyProxy', name: 'envoy-' + name, namespace: ns },
    },
  },

  certificate:
    certificate.new(tlsSecret)
    + certificate.metadata.withNamespace(ns)
    + certificate.spec.withCommonName(wildcard)
    + certificate.spec.withDnsNames([wildcard])
    + certificate.spec.withSecretName(tlsSecret)
    + certificate.spec.issuerRef.withName('letsencrypt')
    + certificate.spec.issuerRef.withKind('ClusterIssuer'),

  // The same certificate in the namespace the gateways are about to move to, so it is issued before the move.
  certificateInGatewayNamespace: self.certificate {
    metadata+: { namespace: cfg.gatewayNamespace },
  },

  gateway: {
    apiVersion: 'gateway.networking.k8s.io/v1',
    kind: 'Gateway',
    metadata: {
      name: name,
      namespace: ns,
      annotations: { 'cert-manager.io/cluster-issuer': 'letsencrypt' } + annotations,
    },
    spec: {
      gatewayClassName: 'envoy-' + name,
      allowedListeners: { namespaces: { from: 'All' } },
      listeners: [
        { name: 'http', protocol: 'HTTP', port: 80, allowedRoutes: { namespaces: { from: 'All' } } },
        {
          name: 'https',
          protocol: 'HTTPS',
          hostname: wildcard,
          port: 443,
          tls: { mode: 'Terminate', certificateRefs: [{ group: '', kind: 'Secret', name: tlsSecret }] },
          allowedRoutes: { namespaces: { from: 'All' } },
        },
      ],
    },
  },
};

{
  exposed: gateway(
    $._config,
    'exposed',
    $._config.exposedAddress,
    if $._config.exposedDnsTarget != '' then { 'external-dns.alpha.kubernetes.io/target': $._config.exposedDnsTarget } else {},
  ),
  internal: gateway($._config, 'internal', $._config.internalAddress),
}
