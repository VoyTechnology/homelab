// User groups managed by the operator. The key is the group name in Pocket ID.
local groups = {
  infra: 'Infra',
  member: 'Member',
  guest: 'Guest',
};

{
  groups: {
    [name]: {
      apiVersion: 'pocketid.internal/v1alpha1',
      kind: 'PocketIDUserGroup',
      metadata: { name: name, namespace: $._config.namespace },
      spec: { friendlyName: groups[name] },
    }
    for name in std.objectFields(groups)
  },
}
