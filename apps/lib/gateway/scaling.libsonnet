// Scaling: replica counts and CPU/memory requests and limits.
{
  // Uses ~70Mi; the library default limit of 1Gi only overcommits the node.
  envoy_gateway_container+:: { resources+: { limits+: { memory: '384Mi' } } },
}
