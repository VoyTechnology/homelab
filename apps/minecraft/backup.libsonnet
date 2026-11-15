// The sidecar tars /data daily into an emptyDir; the script copies each archive to the node's disk.
{
  backup_env+:: {
    POST_BACKUP_SCRIPT: |||
      #!/bin/sh
      set -eu
      # /backups is an emptyDir, so without a copy out of the pod the archives die with it.
      # The image has neither bash nor rsync: POSIX sh and busybox only.
      latest=$(ls -t /backups/world-*.tgz | head -n 1)
      echo "Copying $latest to %(path)s"
      cp "$latest" /nfs/
      # mc-backup only prunes /backups, so prune the copies here.
      find /nfs -maxdepth 1 -name 'world-*.tgz' -mtime +%(days)d -delete
    ||| % { path: $._config.backupHostPath, days: $._config.backupRetentionDays },
  },

  // The pod is pinned to the node, so use its disk directly. It must be owned by 1000:2000.
  volumes+:: {
    nfs: { hostPath: { path: $._config.backupHostPath, type: 'DirectoryOrCreate' } },
  },
  backup_container+:: {
    volumeMounts+: [{ name: 'nfs', mountPath: '/nfs' }],
  },
}
