datacenter = "{{ nomad_dc }}"
data_dir   = "/opt/nomad"
region     = "{{ nomad_region }}"

bind_addr = {% raw %}"{{ GetInterfaceIP \"tailscale0\" }}"{% endraw %}

server {
    enabled          = true
    bootstrap_expect = 1
}

consul {
    server_auto_join = true
    client_auto_join = true
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
