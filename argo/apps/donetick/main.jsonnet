local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.35/main.libsonnet';

local deployment = k.apps.v1.deployment;
local container = k.core.v1.container;
local volume = k.core.v1.volume;
local volumeMount = k.core.v1.volumeMount;
local svc = k.core.v1.service;
local servicePort = k.core.v1.servicePort;

local labels = { 'app.kubernetes.io/name': 'donetick' };
local port = 2021;

local secretEnv(name, secret, key) = {
  name: name,
  valueFrom: { secretKeyRef: { name: secret, key: key } },
};

{
  // Secrets (JWT, Telegram, OIDC client_id/client_secret) are passed as DT_* env vars, which override this file.
  _config:: {
    name: 'selfhosted',
    is_done_tick_dot_com: false,
    is_user_creation_disabled: true,
    telegram: { token: '' },
    pushover: { token: '' },
    database: {
      type: 'sqlite',
      migration: true,
      // these are only required for postgres
      host: 'secret',
      port: 5432,
      user: 'secret',
      password: 'secret',
      name: 'secret',
    },
    jwt: {
      // Handled by ENV VAR
      secret: 'change_this_to_a_secure_random_string_32_characters_long',
      session_time: '168h',
      max_refresh: '168h',
    },
    server: {
      port: port,
      read_timeout: '10s',
      write_timeout: '10s',
      rate_period: '60s',
      rate_limit: 300,
      cors_allow_origins: [
        'http://localhost:5173',
        'http://localhost:7926',
        // the below are required for the android app to work
        'https://localhost',
        'capacitor://localhost',
      ],
      serve_frontend: true,
    },
    logging: { level: 'info', encoding: 'json', development: false },
    scheduler_jobs: { due_job: '30m', overdue_job: '3h', pre_due_job: '3h' },
    email: { host: null, port: null, key: null, email: null, appHost: null },
    // client_id and client_secret come from DT_OAUTH2_CLIENT_ID / DT_OAUTH2_CLIENT_SECRET.
    oauth2: {
      name: 'Pocket ID',
      auth_url: 'https://%s/authorize' % $._oidcHost,
      token_url: 'https://%s/api/oidc/token' % $._oidcHost,
      user_info_url: 'https://%s/api/oidc/userinfo' % $._oidcHost,
      redirect_url: 'https://%s/auth/oauth2' % $._host,
    },
    // Real-time configuration
    realtime: {
      enabled: true,
      sse_enabled: true,
      heartbeat_interval: '60s',
      connection_timeout: '120s',
      max_connections: 1000,
      max_connections_per_user: 5,
      event_queue_size: 2048,
      cleanup_interval: '2m',
      stale_threshold: '5m',
      enable_compression: true,
      enable_stats: true,
      allowed_origins: ['*'],
    },
  },

  configmap: k.core.v1.configMap.new('donetick-config', {
    'selfhosted.yaml': std.manifestYamlDoc($._config),
  }) + k.core.v1.configMap.metadata.withLabels(labels),

  external_secret: {
    apiVersion: 'external-secrets.io/v1',
    kind: 'ExternalSecret',
    metadata: { name: 'donetick-secrets' },
    spec: {
      refreshInterval: '1h',
      secretStoreRef: { kind: 'ClusterSecretStore', name: 'cluster-secrets' },
      target: { name: 'donetick-secrets', creationPolicy: 'Owner' },
      data: [
        { secretKey: 'DT_JWT_SECRET', remoteRef: { key: 'shared-secrets', property: 'donetick_jwt_secret' } },
        { secretKey: 'DT_TELEGRAM_TOKEN', remoteRef: { key: 'shared-secrets', property: 'donetick_telegram_token' } },
      ],
    },
  },

  // The operator creates the donetick-oidc-credentials Secret next to this client.
  oidc_client: {
    apiVersion: 'pocketid.internal/v1alpha1',
    kind: 'PocketIDOIDCClient',
    metadata: {
      name: 'donetick',
      annotations: { 'argocd.argoproj.io/sync-options': 'SkipDryRunOnMissingResource=true' },
    },
    spec: {
      name: 'Donetick',
      callbackUrls: [
        $._config.oauth2.redirect_url,
        // The Donetick mobile app returns to this custom scheme after login.
        'donetick://auth/oauth2',
      ],
      launchUrl: 'https://%s' % $._host,
      allowedUserGroups: [{ name: 'member', namespace: $._pocketidNamespace }],
      secret: { name: 'donetick-oidc-credentials' },
    },
  },

  pvc: k.core.v1.persistentVolumeClaim.new('donetick-data-pvc')
       + k.core.v1.persistentVolumeClaim.metadata.withLabels(labels)
       + k.core.v1.persistentVolumeClaim.spec.withAccessModes(['ReadWriteOnce'])
       + k.core.v1.persistentVolumeClaim.spec.withStorageClassName('longhorn')
       + k.core.v1.persistentVolumeClaim.spec.resources.withRequests({ storage: '10Gi' }),

  deployment:
    deployment.new('donetick', replicas=1, podLabels=labels, containers=[
      container.new('donetick', $._images.donetick)
      + container.withPorts([k.core.v1.containerPort.newNamed(port, 'http')])
      + container.withEnv([
        secretEnv('DT_JWT_SECRET', 'donetick-secrets', 'DT_JWT_SECRET'),
        secretEnv('DT_TELEGRAM_TOKEN', 'donetick-secrets', 'DT_TELEGRAM_TOKEN'),
        secretEnv('DT_OAUTH2_CLIENT_ID', 'donetick-oidc-credentials', 'client_id'),
        secretEnv('DT_OAUTH2_CLIENT_SECRET', 'donetick-oidc-credentials', 'client_secret'),
        { name: 'DT_SQLITE_PATH', value: '/data/donetick.db' },
      ])
      + container.withVolumeMounts([
        volumeMount.new('config-volume', '/config/selfhosted.yaml') + volumeMount.withSubPath('selfhosted.yaml'),
        volumeMount.new('data-volume', '/data'),
      ]),
    ])
    // deployment.new adds a name label to the selector; the selector is immutable, so keep the original.
    + { spec+: { selector: { matchLabels: labels }, template+: { metadata: { labels: labels } } } }
    + deployment.metadata.withLabels(labels)
    // Restart the pod when the rendered config changes.
    + deployment.spec.template.metadata.withAnnotations({ 'checksum/config': std.md5(std.toString($._config)) })
    + deployment.spec.template.spec.withVolumes([
      volume.fromConfigMap('config-volume', 'donetick-config'),
      volume.fromPersistentVolumeClaim('data-volume', 'donetick-data-pvc'),
    ]),

  service: svc.new('donetick', labels, [servicePort.newNamed('http', port, 'http')])
           + svc.metadata.withLabels(labels),

  ingress: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'Ingress',
    metadata: {
      name: 'donetick',
      labels: labels,
      annotations: {
        'cert-manager.io/cluster-issuer': 'letsencrypt',
        // DNS is managed by the Cloudflare tunnel, not external-dns.
        'dns.kubernetes.io/exclude': 'true',
      },
    },
    spec: {
      ingressClassName: 'external',
      tls: [{ hosts: [$._host], secretName: 'donetick-tls' }],
      rules: [{
        host: $._host,
        http: { paths: [{
          path: '/',
          pathType: 'Prefix',
          backend: { service: { name: 'donetick', port: { number: port } } },
        }] },
      }],
    },
  },
}

// Defaults for the Tanka overrides; the ArgoCD application passes the real values.
+ {
  _namespace:: 'donetick',
  _host:: 'chores.bednarzak.com',
  _oidcHost:: 'login.bednarzak.com',
  _pocketidNamespace:: 'pocketid',
  _images:: {
    // renovate: datasource=docker depName=docker.io/donetick/donetick
    donetick: 'donetick/donetick',
  },
}
