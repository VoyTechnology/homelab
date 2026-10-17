// Home Assistant itself (formerly the pajikos/home-assistant Helm chart).
//
// PERSISTENCE: /config lives on the PVC created by the StatefulSet's
// volumeClaimTemplate. The StatefulSet name ('homeassistant'), the template name
// ('homeassistant') and its spec below MUST stay identical to what the chart
// rendered -- together they make the claim `homeassistant-homeassistant-0`, which is
// how the new StatefulSet adopts the existing volume instead of creating a new one.
// The claim is deliberately not a rendered object (Argo never prunes it) and the
// retention policy below stops Kubernetes deleting it with the StatefulSet.
local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.35/main.libsonnet';

local container = k.core.v1.container;
local volumeMount = k.core.v1.volumeMount;
local volume = k.core.v1.volume;
local envVar = k.core.v1.envVar;

{
    local this = self,
    local cfg = $._config.homeassistant,
    local name = 'homeassistant',
    // Do not change: the StatefulSet selector is immutable and the Service and
    // ServiceMonitor select on it.
    local selector = {
        'app.kubernetes.io/name': name,
        'app.kubernetes.io/instance': name,
    },
    // Metadata labels. Kept apart from `selector`: the selector is immutable and must
    // never grow, while these may change freely.
    local labels = selector + { 'app.kubernetes.io/managed-by': 'Tanka' },
    local devices = {
        'zigbee-dongle': $._config.zigbeeDongle,
        'thread-dongle': $._config.threadDongle,
    },
    local sync = cfg.configSync,

    haServiceAccount: {
        apiVersion: 'v1',
        kind: 'ServiceAccount',
        metadata: { name: name, labels: labels },
    },

    haService: {
        apiVersion: 'v1',
        kind: 'Service',
        metadata: { name: name, labels: labels },
        spec: {
            type: 'ClusterIP',
            ports: [{ name: 'http', port: cfg.port, targetPort: 'http', protocol: 'TCP' }],
            selector: selector,
        },
    },

    haIngress: {
        apiVersion: 'networking.k8s.io/v1',
        kind: 'Ingress',
        metadata: {
            name: name,
            labels: labels,
            annotations: {
                'cert-manager.io/cluster-issuer': 'letsencrypt',
                // Do not create the DNS entry as its being managed by the tunnel.
                'dns.kubernetes.io/exclude': 'true',
            },
        },
        spec: {
            ingressClassName: cfg.ingressClass,
            tls: [{ hosts: [$._config.domain], secretName: 'homeassistant-tls' }],
            rules: [{
                host: $._config.domain,
                http: { paths: [{
                    path: '/',
                    pathType: 'ImplementationSpecific',
                    backend: { service: { name: name, port: { number: cfg.port } } },
                }] },
            }],
        },
    },

    // Exposes the built-in Prometheus integration (`prometheus:` in configuration.yaml)
    // at /api/prometheus. Alloy already watches ServiceMonitor targets cluster-wide
    // (prometheus.operator.servicemonitors in alloy-config.alloy), so no scrape config
    // changes are needed there. HA's API requires auth on every request, so the endpoint
    // uses the bearer token of the homeassistant-matterhub secret -- HA tokens aren't
    // scope-limited, so reusing it avoids provisioning a second one just for scraping.
    haServiceMonitor: {
        apiVersion: 'monitoring.coreos.com/v1',
        kind: 'ServiceMonitor',
        metadata: { name: name, labels: labels },
        spec: {
            endpoints: [{
                port: 'http',
                path: '/api/prometheus',
                interval: cfg.metricsInterval,
                bearerTokenSecret: cfg.metricsTokenSecret,
            }],
            namespaceSelector: { matchNames: ['homeassistant'] },
            selector: { matchLabels: selector },
        },
    },

    haContainer::
        container.new(name, $._images.homeassistant)
        + container.withImagePullPolicy('IfNotPresent')
        + container.withPorts([{ name: 'http', containerPort: cfg.port, protocol: 'TCP' }])
        // Zigbee/Thread dongles need the extra permissions.
        + container.securityContext.withPrivileged(true)
        + {
            livenessProbe: {
                httpGet: { path: '/', port: 'http', scheme: 'HTTP' },
                periodSeconds: 20, timeoutSeconds: 2, failureThreshold: 3, successThreshold: 1,
            },
            readinessProbe: {
                httpGet: { path: '/', port: 'http', scheme: 'HTTP' },
                periodSeconds: 10, timeoutSeconds: 1, failureThreshold: 3, successThreshold: 1,
            },
        }
        + container.withVolumeMounts(
            [volumeMount.new(name, '/config')]
            + [volumeMount.new(d, devices[d]) for d in std.objectFields(devices)]
        ),

    // Applies the git-sync'd `generated` tree of ha-data to /config (see sync.py).
    haSyncSidecars:: [
        container.new('git-sync', $._images.gitSync)
        + container.securityContext.withRunAsUser(0)
        + container.withEnv([
            envVar.new('GITSYNC_REPO', sync.repo),
            envVar.new('GITSYNC_REF', sync.ref),
            envVar.new('GITSYNC_ROOT', '/git'),
            envVar.new('GITSYNC_LINK', 'current'),
            envVar.new('GITSYNC_PERIOD', sync.period),
            envVar.new('GITSYNC_USERNAME', 'x-access-token'),
            envVar.fromSecretRef('GITSYNC_PASSWORD', 'ha-data-git', 'token'),
        ])
        + container.withVolumeMounts([volumeMount.new('git', '/git')])
        + container.resources.withRequests({ cpu: '10m', memory: '32Mi' })
        + container.resources.withLimits({ memory: '128Mi' }),

        // Same image as HA so check_config validates against the running version.
        container.new('config-applier', $._images.homeassistant)
        + container.withCommand(['python3', '-u', '/scripts/sync.py'])
        + container.withEnv([
            envVar.new('SRC', '/git/current'),
            // hostNetwork: HA is reachable on the pod's own loopback.
            envVar.new('HA_URL', 'http://127.0.0.1:%d' % cfg.port),
            envVar.fromSecretRef('HA_TOKEN', cfg.metricsTokenSecret.name, cfg.metricsTokenSecret.key),
        ])
        + container.withVolumeMounts([
            volumeMount.new(name, '/config'),
            volumeMount.new('git', '/git', readOnly=true),
            volumeMount.new('sync-script', '/scripts', readOnly=true),
        ])
        + container.resources.withRequests({ cpu: '20m', memory: '128Mi' })
        + container.resources.withLimits({ memory: '768Mi' }),
    ],

    haStatefulSet: {
        apiVersion: 'apps/v1',
        kind: 'StatefulSet',
        metadata: { name: name, labels: labels },
        spec: {
            serviceName: name,
            replicas: 1,
            selector: { matchLabels: selector },
            // Never let Kubernetes garbage-collect the /config claim (this is the
            // default; spelled out because the data on it is not reproducible).
            persistentVolumeClaimRetentionPolicy: { whenDeleted: 'Retain', whenScaled: 'Retain' },
            template: {
                metadata: {
                    labels: labels,
                } + (if sync.enabled then {
                    // Restart the pod sidecars when the script changes.
                    annotations: { 'checksum/sync-script': std.md5(importstr 'sync.py') },
                } else {}),
                spec: {
                    hostNetwork: true,
                    serviceAccountName: name,
                    nodeSelector: { 'kubernetes.io/hostname': $._config.nodeName },
                    containers: [this.haContainer] + (if sync.enabled then this.haSyncSidecars else []),
                    volumes:
                        [volume.fromHostPath(d, devices[d]) for d in std.objectFields(devices)]
                        + (if sync.enabled then [
                            volume.fromEmptyDir('git'),
                            volume.fromConfigMap('sync-script', 'ha-config-sync'),
                        ] else []),
                },
            },
            // IMMUTABLE and identical to the Helm render: name + spec define the claim
            // (homeassistant-homeassistant-0) holding /config. No storageClassName: the
            // existing claim uses the cluster default.
            volumeClaimTemplates: [{
                metadata: { name: name },
                spec: {
                    accessModes: ['ReadWriteOnce'],
                    resources: { requests: { storage: cfg.storageSize } },
                },
            }],
        },
    },

    // Config-sync objects; empty (and so nothing is rendered) unless enabled.
    haSync: if !sync.enabled then {} else {
        script: {
            apiVersion: 'v1',
            kind: 'ConfigMap',
            metadata: { name: 'ha-config-sync' },
            data: { 'sync.py': importstr 'sync.py' },
        },

        // Read-only GitHub token for the ha-data repo.
        secret: {
            apiVersion: 'external-secrets.io/v1',
            kind: 'ExternalSecret',
            metadata: { name: 'ha-data-git' },
            spec: {
                refreshInterval: '1h',
                secretStoreRef: { kind: 'ClusterSecretStore', name: 'cluster-secrets' },
                target: { name: 'ha-data-git', creationPolicy: 'Owner' },
                data: [{
                    secretKey: 'token',
                    remoteRef: { key: 'shared-secrets', property: sync.tokenProperty },
                }],
            },
        },
    },
}
