// Pinned here, not in the library, so Renovate can bump it. Keep the CRDs of the library in step.
{
  _images+:: {
    // renovate: datasource=docker depName=oci.external-secrets.io/external-secrets/external-secrets
    externalSecrets: 'oci.external-secrets.io/external-secrets/external-secrets:v0.18.2',
  },
}
