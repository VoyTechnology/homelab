datacenter = "nvn1"
data_dir   = "/opt/nomad"
region     = "eu-west"

client {
    enabled = true
    server_join {
        retry_join = [ "192.168.1.10" ]
    }

    // Add a disk node class
    node_class = "{{ class }}"
}

ports {
    http = 5646
    rpc  = 5647
    serf = 5648
}

telemetry {
    collection_interval        = "1s"
    disable_hostname           = true
    prometheus_metrics         = true
    publish_allocation_metrics = true
    publish_node_metrics       = true
}