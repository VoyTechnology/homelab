// Operator release manifests (CRDs, RBAC, Deployment), vendored by jsonnet-bundler.
local install = std.parseYaml(importstr 'github.com/aclerici38/pocket-id-operator/dist/install.yaml');

local clusterScoped = ['Namespace', 'CustomResourceDefinition', 'ClusterRole', 'ClusterRoleBinding'];

// withSyncWave orders the CRDs/operator before the instance that depends on them.
local withSyncWave(wave) = {
  metadata+: { annotations+: { 'argocd.argoproj.io/sync-wave': std.toString(wave) } },
};

// The release manifest hardcodes the pocket-id-operator-system namespace; move it to ours.
local relocate(obj, namespace) =
  obj
  + (if std.member(clusterScoped, obj.kind) then {} else { metadata+: { namespace: namespace } })
  + (if std.objectHas(obj, 'subjects') then {
       subjects: [s + { namespace: namespace } for s in obj.subjects],
     } else {});

local operator = {
  ['%s-%s' % [std.asciiLower(o.kind), o.metadata.name]]: relocate(o, $._namespace) + withSyncWave(0)
  for o in install
  if o != null && o.kind != 'Namespace'
};

operator + {
  encryption_key: {
    apiVersion: 'external-secrets.io/v1',
    kind: 'ExternalSecret',
    metadata: { name: 'pocketid-encryption-key' } + withSyncWave(1).metadata,
    spec: {
      refreshInterval: '1h',
      secretStoreRef: { kind: 'ClusterSecretStore', name: 'cluster-secrets' },
      target: { name: 'pocketid-encryption-key', creationPolicy: 'Owner', deletionPolicy: 'Retain' },
      data: [{
        secretKey: 'encryptionKey',
        // Defaults spelled out so Argo does not report drift against what ESO fills in.
        remoteRef: {
          key: 'shared-secrets',
          property: 'pocketid_encryption_key',
          conversionStrategy: 'Default',
          decodingStrategy: 'None',
          metadataPolicy: 'None',
        },
      }],
    },
  },

  instance: {
    apiVersion: 'pocketid.internal/v1alpha1',
    kind: 'PocketIDInstance',
    metadata: { name: 'pocket-id' } + withSyncWave(1).metadata + {
      annotations+: { 'argocd.argoproj.io/sync-options': 'SkipDryRunOnMissingResource=true' },
    },
    spec: {
      appUrl: 'https://%s' % $._host,
      encryptionKey: { valueFrom: { secretKeyRef: { name: 'pocketid-encryption-key', key: 'encryptionKey' } } },
      persistence: { enabled: true, size: '1Gi' },
      // Traffic arrives via the in-cluster cloudflared pod, so only trust private ranges.
      trustedProxies: {
        enabled: true,
        cidrs: ['10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16', '100.64.0.0/10', '127.0.0.1/32', '::1/128', 'fd00::/8'],
      },
    },
  },

  ingress: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'Ingress',
    metadata: {
      name: 'pocketid',
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
          // The operator names the Service after the PocketIDInstance.
          backend: { service: { name: 'pocket-id', port: { number: 1411 } } },
        }] },
      }],
    },
  },
}

// Defaults for the Tanka overrides; the ArgoCD application passes the real values.
+ {
  _namespace:: 'pocketid',
  _host:: 'login.bednarzak.com',
}
