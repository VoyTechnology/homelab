encrypt    = "Jjbwu6WcbonRraNbOeYnIg=="
data_dir   = "/opt/consul"
retry_join = ["{{ master_ip }}"]
datacenter = "{{ consul_dc }}"

ports {
    grpc = 8502
}

connect {
    enabled = true
}
