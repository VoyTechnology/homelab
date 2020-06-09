encrypt    = "Jjbwu6WcbonRraNbOeYnIg=="
data_dir   = "/opt/consul"
retry_join = ["192.168.1.10"]
datacenter = "nvn1"

ports {
    grpc = 8502
}

connect {
    enabled = true
}