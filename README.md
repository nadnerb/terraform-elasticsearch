Elasticsearch cluster on AWS using Terraform
=============

This project will create an elasticsearch cluster in AWS using multiple availability zones. The cluster is located in a private subnet and communicates via private ip addresses.

## Requirements

* Terraform >= v0.5.1
* Elasticsearch IAM profile called elasticSearchNode with [EC2 permissions](https://github.com/elastic/elasticsearch-cloud-aws#recommended-ec2-permissions)

Packer AMI's

We use prebuild Packer AMI's built from these projects:

* [packer-elasticsearch](https://github.com/nadnerb/packer-elastic-search)

## Installation

* install [Terraform](https://www.terraform.io/) and add it to your PATH.
* clone this repo.
* `terraform get`

## Configuration

Create a configuration file such as `~/.aws/default.tfvars` which can include mandatory and optional variables such as:

```
aws_access_key="<your aws access key>"
aws_secret_key="<your aws access secret>"
key_name="<your private key name>"
key_name="<key name>"

stream_tag="<used for aws resource groups>"

aws_region="ap-southeast-2"
aws_elasticsearch_amis.ap-southeast-2="ami-7ff38945"

# internal hosted zone
hosted_zone_name="<some.internal>"

aws_subnet_cidr_a="<subnet a cidr>"
aws_subnet_public_cidr_a="<subnet a public cidr>"
aws_subnet_cidr_b="<subnet b cidr>"
aws_subnet_public_cidr_b="<subnet b public cidr>"

# required by ansible
es_cluster="<elasticsearch cluster name>"
es_environment="<elasticsearch environment>"
```

You can also modify the `variables.tf` file, replacing correct values for `aws_amis` for your region:

```
variable "aws_elasticsearch_amis" {
  default = {
		ap-southeast-2 = "ami-xxxxxxx"
  }
}
```

These variables can also be overriden when running terraform like so:

```
terraform (plan|apply|destroy) -var 'aws_elasticsearch_amis.ap-southeast-2=foozie'
```

The variables.tf terraform file can be further modified, for example it defaults to `ap-southeast-2` for the AWS region.

## Using Terraform

Execute the plan to see if everything works as expected.

```
terraform plan -var-file ~/.aws/default.tfvars -state='environment/development.tfstate'
```

If all looks good, lets build our infrastructure!

```
terraform apply -var-file ~/.aws/default.tfvars -state='environment/development.tfstate'
```

### Multiple security groups

A security group is created using terraform that opens up Elasticsearch and ssh ports. We can also add extra pre-existing security groups to our Elasticsearch instances like so:

```
terraform plan -var-file '~/.aws/default.tfvars' -var 'additional_security_groups=sg-xxxx, sg-yyyy'
```

## TODO

* Update this readme
* Use consul template for configuration

