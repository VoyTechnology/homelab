(import '../../lib/flux.libsonnet').new(
  'bet1',
  // The private home-services repository renders its apps to the `generated` branch.
  extraSources=[{
    name: 'home-services',
    url: 'ssh://git@github.com/VoyTechnology/home-services',
    branch: 'generated',
    path: './clusters/bet1',
  }],
)
