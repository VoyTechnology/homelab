local k = import "github.com/jsonnet-libs/k8s-libsonnet/1.35/main.libsonnet";

{
  grafana: {
    deployment: k.apps.v1.deployment.new('grafana', replicas=1, containers=[
      k.core.v1.container.new('grafana', 'grafana/grafana')
      + k.core.v1.container.withPorts([
        k.core.v1.containerPort.newNamed(name='ui', containerPort=$._config.port),
      ]),
    ]),
  },
}