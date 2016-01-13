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
    cidr_blocks = ["0.0.0.0/0"]
  }

  # elastic ports from anywhere.. we are using private ips so shouldn't
  # have people deleting our indexes just yet
  ingress {
    from_port = 9200
    to_port = 9400
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

resource "template_file" "user_data" {
  template = "${path.module}/templates/user-data.tpl"

  vars {
    dns_server              = "${var.dns_server}"
    num_nodes               = "${var.instances}"
    consul_dc               = "${var.consul_dc}"
    atlas                   = "${var.atlas}"
    atlas_token             = "${var.atlas_token}"
    volume_name             = "${var.volume_name}"
    elasticsearch_data_dir  = "${var.elasticsearch_data}"
    es_cluster  = "${var.es_cluster}"
    es_environment  = "${var.es_environment}"
    /*security_groups = "${concat(aws_security_group.elasticsearch.id, ",", var.additional_security_groups)}"*/
    security_groups = "${aws_security_group.elasticsearch.id}"
    aws_region  = "${var.aws_region}"
    availability_zones = "${var.availability_zones}"
  }
}

resource "aws_launch_configuration" "elasticsearch" {
  image_id = "${var.ami}"
  instance_type = "${var.instance_type}"
  security_groups = ["${split(",", replace(concat(aws_security_group.elasticsearch.id, ",", var.additional_security_groups), "/,\\s?$/", ""))}"]
  associate_public_ip_address = false
  ebs_optimized = false
  key_name = "${var.key_name}"
# FIXME
  #iam_instance_profile = "${aws_iam_instance_profile.elasticsearch.id}"
  iam_instance_profile = "elasticSearchNode"
  user_data = "${template_file.user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }

  ebs_block_device {
    device_name = "${var.volume_name}"
    volume_size = "${var.volume_size}"
  }
}

resource "aws_autoscaling_group" "elasticsearch" {
  availability_zones = ["${split(",", var.availability_zones)}"]
  vpc_zone_identifier = ["${split(",", var.subnets)}"]
  name = "elasticsearch-asg-${var.es_cluster}"
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
  /*load_balancers = ["${aws_elb.elasticsearch_elb.name}"]*/
  lifecycle {
    create_before_destroy = true
  }
}

