provider "aws" {
  region = "${var.aws_region}"
}

##############################################################################
# Private subnets
##############################################################################

resource "aws_route_table" "search_a" {
  vpc_id = "${var.vpc_id}"

  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${var.nat_a_id}"
  }

  tags {
    Name = "search private route table a"
    stream = "${var.stream_tag}"
  }
}

resource "aws_route_table" "search_b" {
  vpc_id = "${var.vpc_id}"

  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${var.nat_b_id}"
  }

  tags {
    Name = "search private route table b"
    stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "search_a" {
  vpc_id = "${var.vpc_id}"
  availability_zone = "${concat(var.aws_region, "a")}"
  cidr_block = "${var.subnet_cidr_a}"

  tags {
    Name = "SearchPrivateA"
    stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "search_b" {
  vpc_id = "${var.vpc_id}"
  availability_zone = "${concat(var.aws_region, "b")}"
  cidr_block = "${var.subnet_cidr_b}"

  tags {
    Name = "SearchPrivateB"
    stream = "${var.stream_tag}"
  }
}

resource "aws_route_table_association" "search_a" {
  subnet_id = "${aws_subnet.search_a.id}"
  route_table_id = "${aws_route_table.search_a.id}"
}

resource "aws_route_table_association" "search_b" {
  subnet_id = "${aws_subnet.search_b.id}"
  route_table_id = "${aws_route_table.search_b.id}"
}

##############################################################################
# Elasticsearch
##############################################################################

resource "aws_security_group" "elastic" {
  name = "${var.security_group_name}"
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
    Name = "elasticsearch security group"
    stream = "${var.stream_tag}"
    cluster = "${var.es_cluster}"
  }
}

# elastic instances subnet a
module "elastic_nodes_a" {
  source = "./elastic"

  name = "elasticsearch_${var.environment}-a"
  environment = "${var.environment}"
  iam_profile = "${var.iam_profile}"
  region = "${var.aws_region}"
  ami = "${lookup(var.aws_elasticsearch_amis, var.aws_region)}"
  subnet = "${aws_subnet.search_a.id}"
  instance_type = "${var.instance_type}"
  security_groups = "${concat(aws_security_group.elastic.id, ",", var.additional_security_groups)}"
  key_name = "${var.key_name}"
  num_nodes = "${var.subnet_a_num_nodes}"
  cluster = "${var.es_cluster}"
  es_environment = "${var.es_environment}"
  stream_tag = "${var.stream_tag}"
  role_tag = "elasticsearch"
  costcenter_tag = "${var.costcenter_tag}"
  environment_tag = "${var.environment_tag}"
  volume_name = "${var.volume_name}"
  volume_size = "${var.volume_size}"
}

# elastic instances subnet b
module "elastic_nodes_b" {
  source = "./elastic"

  name = "elasticsearch_${var.environment}-b"
  environment = "${var.environment}"
  iam_profile = "${var.iam_profile}"
  region = "${var.aws_region}"
  ami = "${lookup(var.aws_elasticsearch_amis, var.aws_region)}"
  subnet = "${aws_subnet.search_b.id}"
  instance_type = "${var.instance_type}"
  security_groups = "${concat(aws_security_group.elastic.id, ",", var.additional_security_groups)}"
  key_name = "${var.key_name}"
  num_nodes = "${var.subnet_b_num_nodes}"
  cluster = "${var.es_cluster}"
  es_environment = "${var.es_environment}"
  stream_tag = "${var.stream_tag}"
  role_tag = "elasticsearch"
  costcenter_tag = "${var.costcenter_tag}"
  environment_tag = "${var.environment_tag}"
  volume_name = "${var.volume_name}"
  volume_size = "${var.volume_size}"
}

resource "aws_security_group" "elasticsearch_elb" {
  name = "elasticsearch elb"
  description = "Elasticsearch ports"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${var.elb_allowed_cidr_blocks}"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["${var.elb_allowed_cidr_blocks}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "consul elb security group"
    stream = "${var.stream_tag}"
  }
}

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_record" "elasticsearch_private" {
  zone_id = "${var.private_hosted_zone_id}"
  name = "elasticsearch"
  type = "A"
  ttl = "30"
  records = ["${split(",", module.elastic_nodes_a.private-ips)}", "${split(",", module.elastic_nodes_b.private-ips)}"]
}

