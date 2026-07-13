local k = import "./vendor/github.com/jsonnet-libs/k8s-libsonnet/1.35/main.libsonnet";

{
  // use locals to extract the parts we need
  local deployment = k.apps.v1.deployment,
  local container = k.core.v1.container,
  local containerPort = k.core.v1.containerPort,
  local service = k.core.v1.service,

  grafana: {
    // deployment constructor: name, replicas, containers
    deployment: deployment.new('grafana', replicas=1, containers=[
      // container constructor
      container.new('grafana', 'grafana/grafana')
      + container.withPorts([ // add ports to the container
        containerPort.newNamed(name='ui', containerPort=$._config.port),
      ]),
    ]),
  },
}
