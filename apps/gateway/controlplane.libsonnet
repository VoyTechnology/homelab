// The control plane: opt in to the experimental XListenerSet API.
{
  envoy_gateway_config+:: {
    gatewayAPI: { enabled: ['XListenerSet'] },
  },

  // Uses ~70Mi; the library default limit of 1Gi only overcommits the node.
  envoy_gateway_container+:: { resources+: { limits+: { memory: '384Mi' } } },
}
