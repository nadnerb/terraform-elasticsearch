provider "aws" {
  region = "${var.aws_region}"
}

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_zone" "search" {
  name = "${var.hosted_zone_name}"
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "search internal"
    stream = "${var.stream_tag}"
  }
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
  vpc_id = "${aws_vpc.search.id}"

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
  cidr_block = "${var.aws_subnet_cidr_a}"

  tags {
    Name = "SearchPrivateA"
    stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "search_b" {
  vpc_id = "${aws_vpc.search.id}"
  availability_zone = "${concat(var.aws_region, "b")}"
  cidr_block = "${var.aws_subnet_cidr_b}"

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
  name = "elasticsearch"
  description = "Elasticsearch ports with ssh"
  vpc_id = "${aws_vpc.search.id}"

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

  name = "a"
  region = "${var.aws_region}"
  ami = "${lookup(var.aws_elasticsearch_amis, var.aws_region)}"
  subnet = "${aws_subnet.search_a.id}"
  instance_type = "${var.instance_type}"
  security_groups = "${aws_security_group.elastic.id, ",", var.additional_security_groups)}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  num_nodes = "${var.es_num_nodes_a}"
  cluster = "${var.es_cluster}"
  environment = "${var.es_environment}"
  stream_tag = "${var.stream_tag}"
}

# elastic instances subnet b
module "elastic_nodes_b" {
  source = "./elastic"

  name = "b"
  region = "${var.aws_region}"
  ami = "${lookup(var.aws_elasticsearch_amis, var.aws_region)}"
  subnet = "${aws_subnet.search_b.id}"
  instance_type = "${var.instance_type}"
  security_groups = "${aws_security_group.elastic.id, ",", var.additional_security_groups)}"
  key_name = "${var.key_name}"
  key_path = "${var.key_path}"
  num_nodes = "${var.es_num_nodes_b}"
  cluster = "${var.es_cluster}"
  environment = "${var.es_environment}"
  stream_tag = "${var.stream_tag}"
}

