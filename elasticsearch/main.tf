variable "name" {}

variable "stream_tag" {}
variable "role_tag" {}
variable "environment_tag" {}
variable "costcenter_tag" {}

variable "aws_region" {}
variable "instance_type" {}
variable "ami" {}
variable "iam_profile" {}
variable "subnet" {}
variable "security_groups" {}
variable "key_name" {}
variable "num_nodes" {}

variable "es_environment" {}
variable "es_cluster" {}
variable "es_discovery_security_group" {}
variable "es_discovery_availability_zones" {}

variable "elasticsearch_data_dir" {}
variable "volume_az" {}
variable "volume_name" {}
variable "volume_size" {}
variable "volume_encryption" {}
variable "heap_size" {}

variable "dns_server" {}
variable "consul_dc" {}
variable "atlas" {}
variable "encrypted_atlas_token" {}

resource "template_file" "user_data" {
  template = "${file("${path.module}/templates/user-data.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    dns_server              = "${var.dns_server}"
    consul_dc               = "${var.consul_dc}"
    atlas                   = "${var.atlas}"
    encrypted_atlas_token   = "${var.encrypted_atlas_token}"
    volume_name             = "${var.volume_name}"
    elasticsearch_data_dir  = "${var.elasticsearch_data_dir}"
    heap_size               = "${var.heap_size}"
    es_cluster              = "${var.es_cluster}"
    es_environment          = "${var.es_environment}"
    security_groups         = "${var.es_discovery_security_group}"
    availability_zones      = "${var.es_discovery_availability_zones}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "elastic" {

  instance_type = "${var.instance_type}"

  ami = "${var.ami}"
  iam_instance_profile = "${var.iam_profile}"
  subnet_id = "${var.subnet}"
  user_data = "${template_file.user_data.rendered}"

  associate_public_ip_address = "false"

  vpc_security_group_ids = ["${split(",", replace(var.security_groups, "/,\\s?$/", ""))}"]
  key_name = "${var.key_name}"

  count = 1

  tags {
    Name = "${var.name}"
    consul = "agent-${var.es_environment}"
    es_env = "${var.es_environment}"
    es_cluster = "${var.es_cluster}"
    Stream = "${var.stream_tag}"
    # :-/
    ServerRole = "${var.role_tag}"
    "Cost Center" = "${var.costcenter_tag}"
    Environment = "${var.environment_tag}"
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_ebs_volume" "elastic" {
  availability_zone = "${var.volume_az}"
  size = "${var.volume_size}"
  encrypted = "${var.volume_encryption}"
}

resource "aws_volume_attachment" "elastic" {
  device_name = "${var.volume_name}"
  volume_id = "${aws_ebs_volume.elastic.id}"
  instance_id = "${aws_instance.elastic.id}"
}
