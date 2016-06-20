provider "aws" {
  region = "${var.aws_region}"
}

##############################################################################
# Elasticsearch
##############################################################################

resource "aws_security_group" "elasticsearch" {
  name = "${var.security_group_name}-elasticsearch"
  description = "Elasticsearch ports with ssh"
  vpc_id = "${var.vpc_id}"

  # SSH access from anywhere
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${split(",", var.internal_cidr_blocks)}"]
  }

  # elastic ports from anywhere.. we are using private ips so shouldn't
  # have people deleting our indexes just yet
  ingress {
    from_port = 9200
    to_port = 9400
    protocol = "tcp"
    cidr_blocks = ["${split(",", var.internal_cidr_blocks)}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.es_cluster}-elasticsearch"
    stream = "${var.stream_tag}"
    cluster = "${var.es_cluster}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

module "elastic_nodes_a" {
  source = "./elasticsearch"

  # tags
  stream_tag = "${var.stream_tag}"
  role_tag = "elasticsearch"
  costcenter_tag = "${var.costcenter_tag}"
  environment_tag = "${var.environment_tag}"
  name = "${var.es_environment}-elasticsearch-a"

  iam_profile = "${var.iam_profile}"
  aws_region = "${var.aws_region}"
  ami = "${var.ami}"
  subnet = "${var.subnet_a}"
  instance_type = "${var.instance_type}"
  security_groups = "${concat(aws_security_group.elasticsearch.id, ",", var.additional_security_groups)}"
  key_name = "${var.key_name}"
  num_nodes = "${var.subnet_a_num_nodes}"

  # cluster discovery
  es_environment = "${var.es_environment}"
  es_cluster = "${var.es_cluster}"
  es_discovery_security_group = "${aws_security_group.elasticsearch.id}"
  es_discovery_availability_zones ="${var.es_discovery_availability_zones}"

  elasticsearch_data_dir  = "${var.elasticsearch_data}"
  volume_name = "${var.volume_name}"
  volume_size = "${var.volume_size}"
  heap_size = "${var.heap_size}"

  dns_server = "${var.dns_server}"
  consul_dc = "${var.consul_dc}"
  atlas = "${var.atlas}"
  encrypted_atlas_token = "${var.encrypted_atlas_token}"
}

resource "template_file" "user_data" {
  template = "${file("${path.root}/templates/user-data.tpl")}"

  vars {
    dns_server              = "${var.dns_server}"
    consul_dc               = "${var.consul_dc}"
    atlas                   = "${var.atlas}"
    encrypted_atlas_token   = "${var.encrypted_atlas_token}"
    volume_name             = "${var.volume_name}"
    elasticsearch_data_dir  = "${var.elasticsearch_data}"
    heap_size               = "${var.heap_size}"
    es_cluster              = "${var.es_cluster}"
    es_environment          = "${var.es_environment}"
    security_groups         = "${aws_security_group.elasticsearch.id}"
    aws_region              = "${var.aws_region}"
    availability_zones      = "${var.es_discovery_availability_zones}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "elasticsearch" {
  image_id = "${var.ami}"
  instance_type = "${var.instance_type}"
  security_groups = ["${split(",", replace(concat(aws_security_group.elasticsearch.id, ",", var.additional_security_groups), "/,\\s?$/", ""))}"]
  associate_public_ip_address = false
  ebs_optimized = false
  key_name = "${var.key_name}"
  iam_instance_profile = "${var.iam_profile}"
  user_data = "${template_file.user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }

  ebs_block_device {
    device_name = "${var.volume_name}"
    volume_size = "${var.volume_size}"
    encrypted = "${var.volume_encryption}"
  }
}

resource "aws_autoscaling_group" "elasticsearch" {
  availability_zones = ["${split(",", var.es_discovery_availability_zones)}"]
  vpc_zone_identifier = ["${split(",", var.subnets)}"]
  max_size = "${var.instances}"
  min_size = "${var.instances}"
  desired_capacity = "${var.instances}"
  default_cooldown = 30
  force_delete = true
  launch_configuration = "${aws_launch_configuration.elasticsearch.id}"

  tag {
    key = "Name"
    value = "${format("%s-elasticsearch", var.es_cluster)}"
    propagate_at_launch = true
  }
  tag {
    key = "Stream"
    value = "${var.stream_tag}"
    propagate_at_launch = true
  }
  tag {
    key = "ServerRole"
    value = "Elasticsearch"
    propagate_at_launch = true
  }
  tag {
    key = "Cost Center"
    value = "${var.costcenter_tag}"
    propagate_at_launch = true
  }
  tag {
    key = "Environment"
    value = "${var.environment_tag}"
    propagate_at_launch = true
  }
  tag {
    key = "consul"
    value = "agent"
    propagate_at_launch = true
  }
  tag {
    key = "es_env"
    value = "${var.es_environment}"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

