// Only the Pocket ID client for Seerr. Seerr itself is deployed by the `media` Kustomization,
// outside this repository, into the existing `media` namespace.
(import 'config.libsonnet')
+ (import 'images.libsonnet')
+ (import 'scaling.libsonnet')
+ (import 'oidc.libsonnet')
