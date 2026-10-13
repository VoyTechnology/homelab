local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.35/main.libsonnet';

local deployment = k.apps.v1.deployment;
local container = k.core.v1.container;
local volume = k.core.v1.volume;
local volumeMount = k.core.v1.volumeMount;
local svc = k.core.v1.service;
local servicePort = k.core.v1.servicePort;

local labels = { app: 'paperless' };
local port = 8000;
local nodeName = 's1-bet1';
local storagePath = '/storage/Documents';

// Sub-directories of storagePath; the key is also the volume name and mount path.
local dirs = ['data', 'media', 'consume', 'export'];

local secretEnv(name, secret, key) = {
  name: name,
  valueFrom: { secretKeyRef: { name: secret, key: key } },
};

{
  // Pocket ID is used for login only: accounts are created on first SSO login, groups are not synced.
  // $(VAR) is expanded by Kubernetes from the env entries defined above it, which keeps the client
  // secret out of the manifest.
  _oidcProviders:: {
    openid_connect: {
      APPS: [{
        provider_id: 'pocketid',
        name: 'Pocket ID',
        client_id: '$(OIDC_CLIENT_ID)',
        secret: '$(OIDC_CLIENT_SECRET)',
        settings: { server_url: 'https://%s/.well-known/openid-configuration' % $._oidcHost },
      }],
    },
  },

  external_secret: {
    apiVersion: 'external-secrets.io/v1',
    kind: 'ExternalSecret',
    metadata: { name: 'paperless-secret-key' },
    spec: {
      refreshInterval: '1h',
      secretStoreRef: { kind: 'ClusterSecretStore', name: 'cluster-secrets' },
      target: { name: 'paperless-secret-key', creationPolicy: 'Owner', deletionPolicy: 'Retain' },
      data: [{
        secretKey: 'secretKey',
        // Defaults spelled out so Argo does not report drift against what ESO fills in.
        remoteRef: {
          key: 'shared-secrets',
          property: 'paperless_secret_key',
          conversionStrategy: 'Default',
          decodingStrategy: 'None',
          metadataPolicy: 'None',
        },
      }],
    },
  },

  // The operator creates the paperless-oidc-credentials Secret next to this client.
  oidc_client: {
    apiVersion: 'pocketid.internal/v1alpha1',
    kind: 'PocketIDOIDCClient',
    metadata: {
      name: 'paperless',
      annotations: { 'argocd.argoproj.io/sync-options': 'SkipDryRunOnMissingResource=true' },
    },
    spec: {
      name: 'Paperless',
      callbackUrls: ['https://%s/accounts/oidc/pocketid/login/callback/' % $._host],
      launchUrl: 'https://%s' % $._host,
      allowedUserGroups: [{ name: 'member', namespace: $._pocketidNamespace }],
      secret: { name: 'paperless-oidc-credentials' },
    },
  },

  deployment:
    deployment.new('paperless', replicas=1, podLabels=labels, containers=[
      container.new('paperless', $._images.paperless)
      + container.withPorts([k.core.v1.containerPort.newNamed(port, 'http')])
      + container.withEnv([
        { name: 'PAPERLESS_URL', value: 'https://%s' % $._host },
        { name: 'PAPERLESS_REDIS', value: 'redis://localhost:6379' },
        // Traffic arrives through the in-cluster cloudflared pod.
        { name: 'PAPERLESS_USE_X_FORWARD_HOST', value: 'true' },
        { name: 'PAPERLESS_USE_X_FORWARD_PORT', value: 'true' },
        { name: 'PAPERLESS_ACCOUNT_ALLOW_SIGNUPS', value: 'false' },
        { name: 'PAPERLESS_SOCIALACCOUNT_ALLOW_SIGNUPS', value: 'true' },
        { name: 'PAPERLESS_SOCIAL_AUTO_SIGNUP', value: 'true' },
        { name: 'PAPERLESS_APPS', value: 'allauth.socialaccount.providers.openid_connect' },
        secretEnv('PAPERLESS_SECRET_KEY', 'paperless-secret-key', 'secretKey'),
        secretEnv('OIDC_CLIENT_ID', 'paperless-oidc-credentials', 'client_id'),
        secretEnv('OIDC_CLIENT_SECRET', 'paperless-oidc-credentials', 'client_secret'),
        { name: 'PAPERLESS_SOCIALACCOUNT_PROVIDERS', value: std.toString($._oidcProviders) },
      ])
      + container.withVolumeMounts([volumeMount.new(d, '/usr/src/paperless/' + d) for d in dirs])
      + container.mixin.readinessProbe.httpGet.withPath('/')
      + container.mixin.readinessProbe.httpGet.withPort(port)
      + container.mixin.readinessProbe.withInitialDelaySeconds(30),

      // Task broker; nothing worth persisting.
      container.new('redis', $._images.redis)
      + container.withPorts([k.core.v1.containerPort.new(6379)]),
    ])
    + deployment.spec.strategy.withType('Recreate')
    + deployment.spec.template.spec.withNodeSelector({ 'kubernetes.io/hostname': nodeName })
    + deployment.spec.template.spec.withVolumes([
      volume.fromHostPath(d, '%s/%s' % [storagePath, d]) + { hostPath+: { type: 'DirectoryOrCreate' } }
      for d in dirs
    ]),

  service: svc.new('paperless', labels, [servicePort.newNamed('http', port, port)]),

  ingress: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'Ingress',
    metadata: {
      name: 'paperless',
      annotations: {
        // DNS is managed by the Cloudflare tunnel, not external-dns.
        'dns.kubernetes.io/exclude': 'true',
      },
    },
    spec: {
      ingressClassName: 'external',
      rules: [{
        host: $._host,
        http: { paths: [{
          path: '/',
          pathType: 'Prefix',
          backend: { service: { name: 'paperless', port: { number: port } } },
        }] },
      }],
    },
  },
}

// Defaults for the Tanka overrides; the ArgoCD application passes the real values.
+ {
  _namespace:: 'paperless',
  _host:: 'docs.bednarzak.com',
  _oidcHost:: 'login.bednarzak.com',
  _pocketidNamespace:: 'pocketid',
  _images:: {
    // renovate: datasource=docker depName=ghcr.io/paperless-ngx/paperless-ngx
    paperless: 'ghcr.io/paperless-ngx/paperless-ngx:3.3.1',
    // renovate: datasource=docker depName=docker.io/library/redis
    redis: 'docker.io/library/redis:8.2-alpine',
  },
}
