local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local util = import '../lib/util.libsonnet';

local operator = helm.new('externalsecrets'
    repoURL="https://charts.external-secrets.io",
    chart="external-secrets",
    targetRevision="0.18.2",
);

local extraObjects = helm.extraObjects('externalsecrets');

// Use the kube-system namespace for External Secrets Operator
// as its a cluster-wide operator. 
local namespace = "kube-system";

appset.new('externalsecrets', namespace)
+ appset.addSource(operator)
+ appset.addSource(extraObjects)
