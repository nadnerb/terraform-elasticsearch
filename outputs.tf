output "elasticsearch private ips a" {
  value = "${module.elastic_nodes_a.private-ips}"
}

output "elasticsearch private ips b" {
  value = "${module.elastic_nodes_b.private-ips}"
}
