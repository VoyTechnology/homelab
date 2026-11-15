local es = import 'github.com/jsonnet-libs/external-secrets-libsonnet/1.3/main.libsonnet';
local externalSecret = es.nogroup.v1.externalSecret;
local password = es.generators.v1alpha1.password;

// The RCON password is only used inside the pod, so it is generated once instead of stored in the
// `cluster-secrets` store. `refreshInterval: 0` keeps it from rotating.
{
  rconGenerator:
    password.new($._config.rconSecretName)
    + password.metadata.withNamespace($._config.namespace)
    + password.spec.withLength(32)
    + password.spec.withAllowRepeat(true)
    + password.spec.withNoUpper(false),

  rconSecret:
    externalSecret.new($._config.rconSecretName)
    + externalSecret.metadata.withNamespace($._config.namespace)
    + externalSecret.spec.withRefreshInterval('0')
    + externalSecret.spec.target.withName($._config.rconSecretName)
    + externalSecret.spec.target.withCreationPolicy('Owner')
    + externalSecret.spec.target.withDeletionPolicy('Retain')
    + externalSecret.spec.target.template.withData({ [$._config.rconSecretKey]: '{{ .password }}' })
    + externalSecret.spec.withDataFrom([
      externalSecret.spec.dataFrom.sourceRef.generatorRef.withApiVersion('generators.external-secrets.io/v1alpha1')
      + externalSecret.spec.dataFrom.sourceRef.generatorRef.withKind('Password')
      + externalSecret.spec.dataFrom.sourceRef.generatorRef.withName($._config.rconSecretName),
    ]),
}
