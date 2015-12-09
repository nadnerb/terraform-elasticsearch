output "launch_configuration" {
  value = "${aws_autoscaling_group.elasticsearch.launch_configuration}"
}
