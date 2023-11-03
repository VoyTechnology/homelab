# Home Ansible setup

Create a full Hashicorp stack locally.

---

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
