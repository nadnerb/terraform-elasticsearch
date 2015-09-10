output "private-dns" {
  value = "${join(",", aws_instance.elastic.*.private_dns)}"
}

output "private-ips" {
  value = "${join(",", aws_instance.elastic.*.private_ip)}"
}
