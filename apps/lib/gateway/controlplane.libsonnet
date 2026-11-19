// The control plane: opt in to the experimental XListenerSet API.
{
  envoy_gateway_config+:: {
    gatewayAPI: { enabled: ['XListenerSet'] },
  },

  // Envoy Gateway v1.10 also watches the graduated ListenerSet in gateway.networking.k8s.io, which
  // the library's ClusterRole predates. Without it the pod never becomes ready.
  envoyGatewayClusterRole+: {
    rules+: [
      {
        apiGroups: ['gateway.networking.k8s.io'],
        resources: ['listenersets'],
        verbs: ['get', 'list', 'watch'],
      },
      {
        apiGroups: ['gateway.networking.k8s.io'],
        resources: ['listenersets/status'],
        verbs: ['update'],
      },
    ],
  },
}
