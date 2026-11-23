// Scaling: replica counts and CPU/memory requests and limits.
{
  // Uses ~170Mi (peak 190Mi); the library default limit of 1Gi only overcommits the node.
  envoy_gateway_container+:: {
    resources+: { requests+: { cpu: '10m', memory: '192Mi' }, limits+: { memory: '384Mi' } },
  },

  // Uses ~100Mi and had only 128Mi of headroom.
  controller_container+:: {
    resources: { requests: { cpu: '10m', memory: '128Mi' }, limits: { memory: '256Mi' } },
  },

  // Each Envoy proxy uses ~50Mi and ~20m CPU; the Envoy Gateway default request is 100m/512Mi.
  proxyResources:: { requests: { cpu: '20m', memory: '64Mi' }, limits: { memory: '256Mi' } },
}
