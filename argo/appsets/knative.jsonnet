local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';
local util = import '../lib/util.libsonnet';

local knativeOperatorSource = helm.new('knative',
    repoURL="https://knative.github.io/operator",
    chart="knative-operator",
    targetRevision="v1.17.5",
);

local knativeExtraObjects = helm.extraObjects('knative');

appset.new('knative', 'knative')
+ appset.addSource(knativeOperatorSource)
+ appset.addSource(knativeExtraObjects)
