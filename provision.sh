#!/usr/bin/env bash
# This script acts as a wrapper to Terraform.
#
# Ensure you have aws cli installed:
#
#   sudo apt-get install awscli
#
# $CONFIG_LOCATION/.aws.$ENVIRONMENT needs to contain the following:
#
#   export AWS_ACCESS_KEY_ID=AKEY
#   export AWS_SECRET_ACCESS_KEY=ASECRET
#   REGION=aws-region
#   BUCKET=s3-bucket-name

CONFIG_FILE=".terraform.cfg"
TFSTATE="terraform.tfstate"
ENVIRONMENTS=(dc0 dc2 dc3)
COMMANDS=(apply destroy plan refresh)
SYNC_COMMANDS=(apply destroy refresh)
APP_NAME=terraform-elasticsearch
HELPARGS=("help" "-help" "--help" "-h" "-?")

ACTION=$1
ENVIRONMENT=$2

function help {
  echo "USAGE: ${0} setup <config-location>"
  echo "USAGE: ${0} <action> <environment>"
  echo "USAGE: ${0} upload <environment>"
  echo ""
  echo -n "Valid environments are: "
  local i
  for i in "${ENVIRONMENTS[@]}"; do
    echo -n "$i "
  done
  echo ""
  exit 1
}

function contains_element () {
  local i
  for i in "${@:2}"; do
    [[ "$i" == "$1" ]] && return 0
  done
  return 1
}

function check_file_exists() {
  if [ ! -f $1 ]; then
    return 1
  fi
  return 0
}

function check_setup() {
  if [ -z $CONFIG_LOCATION ]; then
    return 1
  fi
  if [ ! -d $CONFIG_LOCATION ]; then
    return 1
  fi
  return 0
}

# Is terraform in PATH?  If not, it should be.
if which terraform > /dev/null;then
  PATH=$PATH:/usr/local/bin/terraform
fi

# Is this a cry for help?
contains_element "$1" "${HELPARGS[@]}"
if [ "${1}x" == "x" ]; then
  help
fi

# All of the args are mandatory.
if [ $# != 2 ]; then
  help
fi

# Do we need to setup
if [ "$1" == "setup" ]; then
  echo "Setting config location ${2}"
  echo "CONFIG_LOCATION=${2}" > $CONFIG_FILE
  exit 0
fi

# Validate the environment.
contains_element "$2" "${ENVIRONMENTS[@]}"
if [ $? -ne 0 ]; then
  echo "ERROR: $3 is not a valid environment"
  exit 1
fi

# check we have been setup
check_file_exists $CONFIG_FILE
if [ $? -ne 0 ]; then
  echo "ERROR: Please run setup with a config location"
  help
fi

source .terraform.cfg

check_setup
if [ $? -ne 0 ]; then
  echo "ERROR: Please make sure the config directory is set and exists, run setup with a config location"
  echo ""
  help
fi

check_file_exists $CONFIG_LOCATION/.aws.$ENVIRONMENT
if [ $? -ne 0 ]; then
  echo "ERROR: Config [$CONFIG_LOCATION/.aws.$ENVIRONMENT] does not exist"
  echo ""
  help
fi
source $CONFIG_LOCATION/.aws.$ENVIRONMENT

# Pre-flight check is good, let's continue.

BUCKET_KEY="${APP_NAME}/tfstate/${ENVIRONMENT}"

# Are we uploading
if [ "$1" == "upload" ]; then
  echo "Syncing state to S3"
  aws s3 sync --region=$REGION --exclude="*" --include="*.tfstate" ./tfstate/${ENVIRONMENT}/ "s3://${BUCKET}/${BUCKET_KEY}"

  exit 0
fi

# Validate the environment.
contains_element "$1" "${COMMANDS[@]}"
if [ $? -ne 0 ]; then
  echo "ERROR: $3 is not a supported command"
  echo ""
  echo "supported commands are (apply destroy refresh plan)"
  echo ""
  exit 1
fi

TFVARS="${CONFIG_LOCATION}/${APP_NAME}/${ENVIRONMENT}.tfvars"
echo ""
echo "Using variables: $TFVARS"
echo ""

# Bail on errors.
set -e

#make sure the environment dirs exist
mkdir -p tfstate/${ENVIRONMENT}

# Nab the latest tfstate.
aws s3 sync --region=$REGION --exclude="*" --include="*.tfstate" "s3://${BUCKET}/${BUCKET_KEY}" ./tfstate/${ENVIRONMENT}/

TERRAFORM_COMMAND="terraform $ACTION -var-file ${TFVARS} -state=./tfstate/${ENVIRONMENT}/terraform.tfstate"

# Run TF; if this errors out we need to keep going.
set +e

#echo $TERRAFORM_COMMAND
echo ""

$TERRAFORM_COMMAND
EXIT_CODE=$?

set -e

# Upload tfstate to S3.
contains_element "$1" "${SYNC_COMMANDS[@]}"
if [ $? -eq 0 ]; then
  echo "Syncing state to S3"
  aws s3 sync --region=$REGION --exclude="*" --include="*.tfstate" ./tfstate/${ENVIRONMENT}/ "s3://${BUCKET}/${BUCKET_KEY}"
fi

exit $EXIT_CODE
