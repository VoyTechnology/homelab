{
  _config:: {
    // Repository Flux reconciles: the output of the Generate workflow.
    repo: 'ssh://git@github.com/VoyTechnology/homelab-manifests.git',
    branch: 'main',
    // Secret with `identity` (read-only deploy key) and `known_hosts`, created by Ansible
    // (ansible/playbooks/roles/k3s/services/tasks/flux.yml).
    secret: 'homelab-manifests',
    interval: '5m',
  },
}
