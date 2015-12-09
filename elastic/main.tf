variable "name" {}
variable "environment" {}
variable "role_tag" {}
variable "environment_tag" {}
variable "costcenter_tag" {}
variable "iam_profile" {}
variable "region" {}
variable "instance_type" {}
variable "ami" {}
variable "subnet" {}
variable "security_groups" {}
variable "key_name" {}
variable "num_nodes" {}
variable "es_environment" {}
variable "cluster" {}
variable "stream_tag" {}
variable "volume_name" { default = "/dev/sdh" }
variable "volume_size" { default = "10" }


resource "aws_instance" "elastic" {

  instance_type = "${var.instance_type}"

  # Lookup the correct AMI based on the region we specified
  ami = "${var.ami}"
  subnet_id = "${var.subnet}"

  iam_instance_profile = "elasticSearchNode"
  associate_public_ip_address = "false"

  # Our Security groups
  security_groups = ["${split(",", replace(var.security_groups, "/,\s?$/", ""))}"]
  key_name = "${var.key_name}"

  # Elasticsearch nodes
  count = "${var.num_nodes}"

  tags {
    Name = "${var.name}-${count.index+1}"
    consul = "agent-${var.environment}"
    # change to use cluster
    es_env = "${var.es_environment}"
    cluster = "${var.cluster}"
    # required for ops reporting
    Stream = "${var.stream_tag}"
    ServerRole = "${var.role_tag}"
    "Cost Center" = "${var.costcenter_tag}"
    Environment = "${var.environment_tag}"
  }

  ebs_block_device {
    device_name = "${var.volume_name}"
    volume_size = "${var.volume_size}"
  }

}
