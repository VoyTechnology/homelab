# Homelab

Homelab running on k3s

---

## Tools

Necessary tools and their versions are managed using [mise], This way we only have to run one
command to install all the necessary tooling.

```sh
mise install
```

## Creating new Cluster

1. Provision individual machine with Debian
   - Ensure that the `root` user can be logged into using the SSH key
   - Change the hostname to match the naming scheme (`s{n}-{cluster}`)
   - Install, start and enable Tailscale on each node
1. Create a new folder in inventory named `{cluster}`, add the `group_vars` and
   `hosts.ini` file. Refer to each machine using the hostname
1. Run the `site.yml` on the cluster to initialize the initial state

---

## Running a single playbook on the cluster

This is done via Github Actions. The action will connect to the cluster with
Ephemeral Key (this will expire one day, make sure to update). Then run it by
providing the cluster name, and the playbook name to run (include the `_` in the
name, but exclude the `.yml` extension)

[mise]: https://github.com/jdx/mise
