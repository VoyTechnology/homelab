// Helpers for apps deployed by Flux. An app environment renders a map of
// repo-relative paths to YAML, written into homelab-manifests as:
//   clusters/<cluster>/apps/<unit>.yaml   Flux Kustomization, picked up by flux-system
//   apps/<cluster>/<unit>/<kind>-<name>.yaml   the unit's manifests
local flux = import 'github.com/jsonnet-libs/fluxcd-libsonnet/2.9.4/main.libsonnet';
local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.35/main.libsonnet';

local helmRepo = flux.source.v1.helmRepository;
local helmRelease = flux.helm.v2.helmRelease;
local kustomization = flux.kustomize.v1.kustomization;

local fluxNamespace = 'flux-system';

// k8s-libsonnet and friends tag objects with a Tanka-only annotation; drop it.
local clean(obj) =
  local ann = std.get(obj.metadata, 'annotations', {});
  local kept = { [a]: ann[a] for a in std.objectFields(ann) if a != 'tanka.dev/namespaced' };
  obj + { metadata+: if std.length(kept) > 0 then { annotations::: kept } else { annotations:: {} } };

local yaml(obj) = std.manifestYamlDoc(clean(obj), quote_keys=false) + '\n';
local fileName(obj) = '%s-%s.yaml' % [std.asciiLower(obj.kind), obj.metadata.name];

{
  // A namespace owned by Flux. Pruning is disabled so removing an app from Git
  // never deletes the namespace together with its volumes.
  namespace(name, labels={})::
    k.core.v1.namespace.new(name)
    + k.core.v1.namespace.metadata.withLabels(labels)
    + k.core.v1.namespace.metadata.withAnnotations({ 'kustomize.toolkit.fluxcd.io/prune': 'disabled' }),

  helmRepository(name, url)::
    helmRepo.new(name)
    + helmRepo.metadata.withNamespace(fluxNamespace)
    + helmRepo.spec.withInterval('1h')
    + helmRepo.spec.withUrl(url),

  // HelmRelease living in flux-system and installing into `namespace`.
  helmRelease(name, namespace, chart, version, repository, values={}, releaseName=name)::
    helmRelease.new(name)
    + helmRelease.metadata.withNamespace(fluxNamespace)
    + helmRelease.spec.withInterval('1h')
    + helmRelease.spec.withReleaseName(releaseName)
    + helmRelease.spec.withTargetNamespace(namespace)
    + helmRelease.spec.withStorageNamespace(namespace)
    + helmRelease.spec.chart.spec.withChart(chart)
    + helmRelease.spec.chart.spec.withVersion(version)
    + helmRelease.spec.chart.spec.sourceRef.withKind('HelmRepository')
    + helmRelease.spec.chart.spec.sourceRef.withName(repository)
    + helmRelease.spec.chart.spec.sourceRef.withNamespace(fluxNamespace)
    + helmRelease.spec.withValues(values),

  // An independently reconciled set of manifests. Units wait for their
  // dependsOn units to be ready, which is how CRDs are ordered before the
  // objects that use them.
  unit(name, objects, dependsOn=[]):: {
    name: name,
    objects: objects,
    dependsOn: dependsOn,
  },

  // Files for one app in one cluster, keyed by repo-relative path.
  render(cluster, units)::
    std.foldl(
      function(acc, u) acc + {
        ['clusters/%s/apps/%s.yaml' % [cluster, u.name]]:
          yaml(
            kustomization.new(u.name)
            + kustomization.metadata.withNamespace(fluxNamespace)
            + kustomization.spec.withInterval('10m')
            + kustomization.spec.withPath('./apps/%s/%s' % [cluster, u.name])
            + kustomization.spec.withPrune(true)
            + kustomization.spec.withWait(true)
            + kustomization.spec.withTimeout('5m')
            + kustomization.spec.sourceRef.withKind('GitRepository')
            + kustomization.spec.sourceRef.withName('flux-system')
            + (if std.length(u.dependsOn) > 0 then kustomization.spec.withDependsOn([{ name: d } for d in u.dependsOn]) else {})
          ),
      } + {
        ['apps/%s/%s/%s' % [cluster, u.name, fileName(o)]]: yaml(o)
        for o in u.objects
      },
      units,
      {},
    ),
}
