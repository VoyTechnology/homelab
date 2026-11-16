// Helpers shared by the apps for this cluster's conventions. Thin functions returning plain objects,
// so an app can still extend the result with `+ { spec+: ... }`.
{
  secrets: import 'secrets.libsonnet',
}
