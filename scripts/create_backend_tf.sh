#!/bin/bash

# only set exit codes 0 and 1, bootstrap.sh relies on it

# Function to check for existing S3 bucket and DynamoDB table
script_dir=$(dirname "$(readlink -f "$0")")
source "$script_dir/utils.sh"


# Check for required input parameters
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <environment> <stage> <application>"
    exit 1
fi

# Assign input parameters to variables
ENVIRONMENT=$1
STAGE=$2
APPLICATION=$3

check_aws_env_vars
status=$?
if [ $status -ne 0 ]; then
    echo "Please set the missing AWS environment variables and try again." >&2
    exit 1
fi

# Check remote state and set variables
json_output=$(get_tf_remote_state_infra)
status=$?

# Handle the exit status
if [ $status -ne 0 ]; then
    echo "No remote state infrastructure found." >&2
    exit 1
fi

# Parse the JSON output
s3_bucket=$(echo "$json_output" | jq '.s3_bucket')
dynamodb_table=$(echo "$json_output" | jq '.dynamodb_table')
region=$AWS_REGION

# Ensure S3 bucket and DynamoDB table were found
if [ -z "$s3_bucket" ] || [ -z "$dynamodb_table" ]; then
    echo "Either bucket or table not found." >&2
    exit 1
fi

# Construct the key for the backend
key="terraform/state/application=$APPLICATION/stage=$STAGE/environment=$ENVIRONMENT/terraform.tfstate"

# Print the backend.tf content to stdout
cat <<EOF
terraform {
  backend "s3" {
    bucket         = $s3_bucket
    key            = "$key"
    region         = "$region"
    dynamodb_table = $dynamodb_table
  }
}
EOF
