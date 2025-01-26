local appset = import '../lib/appset.libsonnet';
local helm = import '../lib/helm.libsonnet';

local source = helm.new(
  'ingress-external', values={
    minio: {
      ingress: util.ingress('minio', class='internal') {
        // The chart is stupid and does it wrong
        className: 'internal',  // should be ingressClassName
        hosts: [{
          host: '{{ .domain }}',
          paths: [{
    },
  });

appset.new('ingress-external', 'ingress-external')
+ appset.addSource(source)
