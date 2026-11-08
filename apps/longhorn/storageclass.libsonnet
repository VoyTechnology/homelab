local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.35/main.libsonnet';

// For data that is cheap to lose or already redundant (object stores, caches): the default
// `longhorn` class keeps two replicas, which a nearly full disk can make unschedulable.
{
  singleReplicaStorageClass:
    k.storage.v1.storageClass.new('longhorn-single')
    + k.storage.v1.storageClass.withProvisioner('driver.longhorn.io')
    + k.storage.v1.storageClass.withAllowVolumeExpansion(true)
    + k.storage.v1.storageClass.withReclaimPolicy('Delete')
    + k.storage.v1.storageClass.withVolumeBindingMode('Immediate')
    + k.storage.v1.storageClass.withParameters({
      numberOfReplicas: '1',
      staleReplicaTimeout: '30',
      fsType: 'ext4',
      dataLocality: 'disabled',
    }),
}
