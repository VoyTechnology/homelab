local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';
local mimir = import 'mimir/mimir.libsonnet';

local deployment = k.apps.v1.deployment;
local statefulSet = k.apps.v1.statefulSet;

mimir {
  compactor_statefulset+: statefulSet.mixin.spec.withReplicas(1),
  distributor_deployment+: deployment.mixin.spec.withReplicas(1),
  ingester_statefulset+: statefulSet.mixin.spec.withReplicas(1),
  querier_deployment+: deployment.mixin.spec.withReplicas(1),
  query_frontend_deployment+: deployment.mixin.spec.withReplicas(1),
  store_gateway_statefulset+: statefulSet.mixin.spec.withReplicas(1),

  compactor_container+: k.util.resourcesRequests('100m', '128Mi'),
  distributor_container+: k.util.resourcesRequests('100m', '128Mi'),
  ingester_container+: k.util.resourcesRequests('100m', '128Mi'),
  querier_container+: k.util.resourcesRequests('100m', '128Mi'),
  query_frontend_container+: k.util.resourcesRequests('100m', '128Mi'),
  store_gateway_container+: k.util.resourcesRequests('100m', '128Mi'),
}
