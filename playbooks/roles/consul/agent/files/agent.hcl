encrypt    = "Jjbwu6WcbonRraNbOeYnIg=="
data_dir   = "/opt/consul"
retry_join = ["{{ consul_servers | join(',') }}"]
datacenter = "{{ consul_dc }}"
recursors  = ["{{ consul_dns_recursors | join(',') }}"]

ports {
    grpc = 8502
}

connect {
    enabled = true
}
