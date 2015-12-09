### MANDATORY ###
variable "private_hosted_zone_id" {}
/*variable "private_hosted_zone_name" {}*/

variable "role_tag" {
  description = "Role of the ec2 instance, defaults to <SERVICE>"
  default = "SERVICE"
}

variable "environment_tag" {
  description = "Role of the ec2 instance, defaults to <DEV>"
  default = "DEV"
}

variable "costcenter_tag" {
  description = "Role of the ec2 instance, defaults to <DEV>"
  default = "DEV"
}

# group our resources
variable "stream_tag" {
  default = "default"
}

variable "environment" {
  default = "default"
}

variable "es_environment" {
  default = "elasticsearch"
}

variable "es_cluster" {
  default = "elasticsearch"
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

### MANDATORY ###
variable "iam_profile" {
  description = "Elasticsearch IAM profile"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default = "ap-southeast-2"
}

variable "availability_zones" {
  description = "AWS region to launch servers."
  default = "ap-southeast-2a,ap-southeast-2b"
}

variable "security_group_name" {
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

variable "external_cidr_blocks"{
  default = "0.0.0.0/0"
}

### MANDATORY ###
# DEPRECATED
/*variable "nat_a_id" {*/
  /*description = "nat a id for subnet routes"*/
/*}*/

### MANDATORY ###
# DEPRECATED
/*variable "nat_b_id" {*/
  /*description = "nat b id for subnet routes"*/
/*}*/

###################################################################
# Subnet configuration below
###################################################################

### MANDATORY ###
# DEPRECATED
/*variable "subnet_cidr_a" {*/
  /*description = "Subnet A cidr block"*/
/*}*/

### MANDATORY ###
# DEPRECATED
/*variable "subnet_cidr_b" {*/
  /*description = "Subnet B cidr block"*/
/*}*/

### MANDATORY ###
variable "subnets" {
  description = "subnets to deploy into"
}

###################################################################
# Elasticsearch configuration below
###################################################################

### MANDATORY ###
# Amazon Linux built by packer
# See https://github.com/nadnerb/packer-elastic-search
variable "ami" {
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

# total number of nodes
variable "instances" {
  description = "total instances"
  default = "2"
}

#DEPRECATED
# number of nodes in zone a
variable "subnet_a_num_nodes" {
  description = "Elastic nodes in a"
  default = "1"
}

#DEPRECATED
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

variable "volume_name" {
  default = "/dev/sdh"
}

variable "volume_size" {
  default = "10"
}

variable "elasticsearch_data" {
  default = "/opt/elasticearch/data"
}

###################################################################
# Consul configuration below
###################################################################

variable "dns_server" {
}

variable "consul_dc" {
  default = "dev"
}

variable "atlas" {
  default = "example/atlas"
}

variable "atlas_token" {
}
