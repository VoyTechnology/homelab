datacenter = "{{ nomad_dc }}"
data_dir   = "/opt/nomad"
region     = "{{ nomad_region }}"

bind_addr = "0.0.0.0"

addresses {
    http = {% raw %}"{{ GetInterfaceIP \"tailscale0\" }}"{% endraw %}
    rpc  = {% raw %}"{{ GetInterfaceIP \"tailscale0\" }}"{% endraw %}
    serf = {% raw %}"{{ GetInterfaceIP \"tailscale0\" }}"{% endraw %}
}

advertise {
    http = {% raw %}"{{ GetInterfaceIP \"tailscale0\" }}"{% endraw %}
    rpc  = {% raw %}"{{ GetInterfaceIP \"tailscale0\" }}"{% endraw %}
    serf = {% raw %}"{{ GetInterfaceIP \"tailscale0\" }}"{% endraw %}
}

client {
    enabled = true

    options {
        docker.privileged.enabled = "true"
        docker.volumes.enabled    = "true"
    }

    network_interface = "tailscale0"
}

consul {
    client_auto_join = true
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
