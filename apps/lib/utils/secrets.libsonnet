local es = import 'github.com/jsonnet-libs/external-secrets-libsonnet/1.3/main.libsonnet';
local externalSecret = es.nogroup.v1.externalSecret;

{
  // An ExternalSecret filling the Secret `name` from properties of the `shared-secrets` entry in the
  // `cluster-secrets` store. `properties` maps Secret key -> property.
  fromShared(name, properties)::
    externalSecret.new(name)
    + externalSecret.spec.withRefreshInterval('1h')
    + externalSecret.spec.secretStoreRef.withKind('ClusterSecretStore')
    + externalSecret.spec.secretStoreRef.withName('cluster-secrets')
    + externalSecret.spec.target.withName(name)
    + externalSecret.spec.target.withCreationPolicy('Owner')
    + externalSecret.spec.target.withDeletionPolicy('Retain')
    + externalSecret.spec.withData([
      externalSecret.spec.data.withSecretKey(key)
      + externalSecret.spec.data.remoteRef.withKey('shared-secrets')
      + externalSecret.spec.data.remoteRef.withProperty(properties[key])
      for key in std.objectFields(properties)
    ]),
}
