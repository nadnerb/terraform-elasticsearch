output "ecs iam id" {
  value = "${aws_iam_instance_profile.elasticsearch.id}"
}
