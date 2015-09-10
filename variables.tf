### MANDATORY ###
variable "private_hosted_zone_name" {}

# group our resources
variable "stream_tag" {
  default = "default"
}

###################################################################
# AWS configuration below
###################################################################
variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."
  default = "elastic"
}

### MANDATORY ###
variable "key_path" {
  description = "Path to the private portion of the SSH key specified."
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default = "ap-southeast-2"
}

variable "aws_security_group" {
  description = "Name of security group to use in AWS."
  default = "elasticsearch"
}

###################################################################
# Vpc configuration below
###################################################################

### MANDATORY ###
variable "vpc_id" {
  description = "VPC id"
}

### MANDATORY ###
variable "nat_a_id" {
  description = "nat a id for subnet routes"
}

### MANDATORY ###
variable "nat_b_id" {
  description = "nat b id for subnet routes"
}

###################################################################
# Subnet configuration below
###################################################################

### MANDATORY ###
variable "aws_subnet_cidr_a" {
  description = "Subnet A cidr block"
}

### MANDATORY ###
variable "aws_subnet_cidr_b" {
  description = "Subnet B cidr block"
}

###################################################################
# Elasticsearch configuration below
###################################################################

# Ubuntu Precise 14.04 LTS (x64) built by packer
# See https://github.com/nadnerb/packer-elastic-search
variable "aws_elasticsearch_amis" {
  default = {
    ap-southeast-2 = "ami-7ff38945"
  }
}

variable "instance_type" {
  description = "Elasticsearch instance type."
  default = "t2.medium"
}

### MANDATORY ###
# if you have multiple clusters sharing the same es_environment..?
variable "es_cluster" {
  description = "Elastic cluster name"
}

### MANDATORY ###
variable "es_environment" {
  description = "Elastic environment tag for auto discovery"
}

# number of nodes in zone a
variable "subnet_a_num_nodes" {
  description = "Elastic nodes in a"
  default = "1"
}

# number of nodes in zone b
variable "subnet_b_num_nodes" {
  description = "Elastic nodes in b"
  default = "1"
}

# the ability to add additional existing security groups. In our case
# we have consul running as agents on the box
variable "additional_security_groups" {
  default = ""
}

