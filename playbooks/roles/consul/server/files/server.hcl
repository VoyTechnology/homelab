datacenter       = "{{ consul_dc }}"
data_dir         = "/opt/consul"
encrypt          = "Jjbwu6WcbonRraNbOeYnIg=="
server           = true
bootstrap_expect = 1
ui               = true
client_addr      = "0.0.0.0"

primary_datacenter = "{{ consul_dc }}"
domain             = "rnet"

// acl_default_policy = "deny"
acl_down_policy = "extend-cache"

ports {
    grpc = 8502
}

connect {
    enabled = true
}
