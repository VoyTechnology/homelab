// One file per responsibility, merged as mixins. Each component is a home-libsonnet library under its own
// key (they share hidden field names such as `pod_spec`), so a concern file extends one component with
// `<key>+: { ... }`. config.libsonnet holds the knobs.
{
  homeassistant: import 'github.com/VoyTechnology/home-libsonnet/homeassistant/main.libsonnet',
  otbr: import 'github.com/VoyTechnology/home-libsonnet/otbr/main.libsonnet',
  matterServer: import 'github.com/VoyTechnology/home-libsonnet/matter-server/main.libsonnet',
  matterhub: import 'github.com/VoyTechnology/home-libsonnet/matterhub/main.libsonnet',
}
+ (import 'config.libsonnet')
+ (import 'images.libsonnet')
+ (import 'scaling.libsonnet')
+ (import 'namespace.libsonnet')
+ (import 'homeassistant.libsonnet')
+ (import 'otbr.libsonnet')
+ (import 'matter-server.libsonnet')
+ (import 'matterhub.libsonnet')
+ (import 'secrets.libsonnet')
+ (import 'ingress.libsonnet')
+ (import 'route.libsonnet')
+ (import 'reload.libsonnet')
