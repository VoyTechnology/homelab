// Scaling: replica counts and CPU/memory requests and limits.
{
  // Both use under 100Mi; unlimited, a leak could take the node down.
  controller_container+:: { resources+: { limits+: { memory: '256Mi' } } },
  cainjector_container+:: { resources+: { limits+: { memory: '256Mi' } } },
}
