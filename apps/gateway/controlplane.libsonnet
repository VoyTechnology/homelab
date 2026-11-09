// The control plane: opt in to the experimental XListenerSet API.
{
  envoy_gateway_config+:: {
    gatewayAPI: { enabled: ['XListenerSet'] },
  },
}
