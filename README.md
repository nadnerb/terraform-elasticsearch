Elasticsearch cluster on AWS using Terraform
=============

This project will create an elasticsearch cluster in AWS using multiple availability zones. The cluster is located in a private subnet and communicates via private ip addresses.

## Requirements

* Terraform >= v0.6.15
* Elasticsearch IAM profile called elasticSearchNode with [EC2 permissions](https://github.com/elastic/elasticsearch-cloud-aws#recommended-ec2-permissions). You can also use the iam project found in the iam directory. This only needs to be done once per account.

Packer AMI's

We use prebuild Packer AMI's built from these projects:

* [packer-elasticsearch](https://github.com/nadnerb/packer-elasticsearch)

## Installation

* install [Terraform](https://www.terraform.io/) and add it to your PATH.
* clone this repo.
* `terraform get`

## Configuration

### AWS Credentials

We rely on AWS credentials to have been set elsewhere, for example using environment variables. We also use [terraform_exec](https://github.com/nadnerb/terraform_exec) to execute terraform that
saves environment state to S3.

### KMS encrypted consul atlas token

aws kms encrypt --key-id <kms-key-id> --plaintext fileb://<(echo <atlas-token>) --output text --query CiphertextBlob | base64 | base64 -d

This is then provided to terraform via `encrypted_atlas_token`.

### Terraform configuration

Create a configuration file such as `~/.aws/default.tfvars` which can include mandatory and optional variables such as:

```
key_name="<key name>"

stream_tag="<used for aws resource groups>"

aws_region="ap-southeast-2"
ami="ami-7ff38945"

vpc_id="xxx"
additional_security_groups=""

es_cluster="cluster name"
es_environment="dev"
volume_name="/dev/sdh"
volume_size="10"

instances="3"
availability_zones="ap-southeast-2a,ap-southeast-2b"
subnets="subnet-xxxxx,subnet-yyyyy"

# consul variables
dns_server  = "172.100.0.2"
consul_dc   = "dc0"
atlas       = "atlas user"
atlas_token = "atlas token"
# internal hosted zone
```

These variables can also be overriden when running terraform like so:

```
terraform (plan|apply|destroy) -var 'ami=foozie'
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

