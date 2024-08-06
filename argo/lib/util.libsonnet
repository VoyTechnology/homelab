{
  ingress(name): {
    hosts: [name+'.{{ .domain}}'],
    tls: [{
      secretName: name + '-tls',
      hosts: [name+'.{{ .domain}}'],
    }],
  }
}
