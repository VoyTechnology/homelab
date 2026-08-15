// node_exporter: host-level metrics (CPU, memory, disk, network) per node.
// A DaemonSet, unlike Alloy/kube-state-metrics -- this genuinely is
// per-node data, one pod per node reading that node's /proc and /sys.
//
// Shape mirrors the prometheus-node-exporter Helm chart's default
// rendering (verified against chart version 4.55.0 via `helm template`).
// The chart's default nodeAffinity (excluding EKS Fargate/virtual-kubelet
// nodes) is dropped as inert on this cluster -- it's not EKS, so those
// labels never exist and the rule is always satisfied. The chart's
// ServiceMonitor is dropped too: alloy-config.alloy already has a static
// prometheus.scrape target for this Service, so keeping a ServiceMonitor
// as well would double-scrape node_exporter (once via the static target,
// once via prometheus.operator.servicemonitors discovery).
local config = import 'config.libsonnet';
local k = import 'k.libsonnet';

local container = k.core.v1.container;
local containerPort = k.core.v1.containerPort;
local volume = k.core.v1.volume;
local volumeMount = k.core.v1.volumeMount;
local service = k.core.v1.service;
local servicePort = k.core.v1.servicePort;
local serviceAccount = k.core.v1.serviceAccount;
local daemonSet = k.apps.v1.daemonSet;

config + {
  local this = self,

  node_exporter_service_account:
    serviceAccount.new('node-exporter')
    + serviceAccount.withAutomountServiceAccountToken(false),

  // Renovate's jsonnet custom manager only tracks `targetRevision = '...'`
  // assignments, not image tags, so this isn't auto-bumped -- check
  // https://github.com/prometheus/node_exporter/releases occasionally and
  // bump by hand.
  _images+:: {
    node_exporter: 'quay.io/prometheus/node-exporter:v1.11.1',
  },

  node_exporter_container::
    container.new('node-exporter', this._images.node_exporter)
    + container.withArgs([
      '--path.procfs=/host/proc',
      '--path.sysfs=/host/sys',
      '--path.rootfs=/host/root',
      '--path.udev.data=/host/root/run/udev/data',
      '--web.listen-address=[$(HOST_IP)]:9100',
    ])
    + container.withEnv([
      // Matches the chart's service.listenOnAllInterfaces=true default.
      { name: 'HOST_IP', value: '0.0.0.0' },
    ])
    + container.securityContext.withReadOnlyRootFilesystem(true)
    + container.withPorts([
      containerPort.newNamed(name='metrics', containerPort=9100),
    ])
    + container.livenessProbe.httpGet.withPath('/')
    + container.livenessProbe.httpGet.withPort('metrics')
    + container.readinessProbe.httpGet.withPath('/')
    + container.readinessProbe.httpGet.withPort('metrics')
    + container.withVolumeMounts([
      volumeMount.new('proc', '/host/proc', true),
      volumeMount.new('sys', '/host/sys', true),
      volumeMount.new('root', '/host/root', true)
      + volumeMount.withMountPropagation('HostToContainer'),
    ]),

  node_exporter_daemon_set:
    daemonSet.new('node-exporter', [this.node_exporter_container])
    + daemonSet.spec.template.metadata.withAnnotations({
      'cluster-autoscaler.kubernetes.io/safe-to-evict': 'true',
    })
    + daemonSet.spec.updateStrategy.withType('RollingUpdate')
    + daemonSet.spec.updateStrategy.rollingUpdate.withMaxUnavailable(1)
    + daemonSet.spec.template.spec.withServiceAccountName('node-exporter')
    + daemonSet.spec.template.spec.withAutomountServiceAccountToken(false)
    + daemonSet.spec.template.spec.securityContext.withFsGroup(65534)
    + daemonSet.spec.template.spec.securityContext.withRunAsGroup(65534)
    + daemonSet.spec.template.spec.securityContext.withRunAsNonRoot(true)
    + daemonSet.spec.template.spec.securityContext.withRunAsUser(65534)
    + daemonSet.spec.template.spec.withHostNetwork(true)
    + daemonSet.spec.template.spec.withHostPID(true)
    + daemonSet.spec.template.spec.withNodeSelector({ 'kubernetes.io/os': 'linux' })
    + daemonSet.spec.template.spec.withTolerations([
      { effect: 'NoSchedule', operator: 'Exists' },
    ])
    + daemonSet.spec.template.spec.withVolumes([
      volume.fromHostPath('proc', '/proc'),
      volume.fromHostPath('sys', '/sys'),
      volume.fromHostPath('root', '/'),
    ]),

  node_exporter_service:
    service.new(
      'node-exporter',
      this.node_exporter_daemon_set.spec.template.metadata.labels,
      [servicePort.newNamed('metrics', 9100, 9100)],
    ),
}
