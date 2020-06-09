datacenter = "nvn1"
data_dir   = "/opt/nomad"
region     = "eu-west"

server {
    enabled          = true
    bootstrap_expect = 1
}

plugin "raw_exec" {
    config {
        enabled = true
    }
}

telemetry {
    collection_interval        = "1s"
    disable_hostname           = true
    prometheus_metrics         = true
    publish_allocation_metrics = true
    publish_node_metrics       = true
}