#!/bin/bash


script_dir=$(dirname "$(readlink -f "$0")")
source "$script_dir/utils.sh"

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <environment>"
    echo "Example: $0 dev"
    exit 1
fi


# Check git remote origin is set
remote_url=$(git config --get remote.origin.url)

# Check if the remote URL is empty
if [ -z "$remote_url" ]; then
    echo "Error: Git remote 'origin' URL is not set."
    exit 1
else
    echo "Git remote 'origin' URL is set: $remote_url"
fi




ENVIRONMENT=$1
REGION=$AWS_REGION

# yourgithubuser/yourgithubrepo
ORIGIN_REPO=$(git config --get remote.origin.url | sed -e 's,.*:\(.*\)\.git,\1,g')

# yourgithubrepo
REPO_NAME=$(basename $ORIGIN_REPO)

# https://github.com/yourgithubuser/yourgithubrepo
REPO_URL="https://github.com/$ORIGIN_REPO"

APPLICATION=$REPO_NAME

STAGE_NAME="000_init"
STAGE_DIR="infrastructure/environments/$ENVIRONMENT/stages/$STAGE_NAME"




# Check that AWS environment variables are set
check_aws_env_vars

backend_tf_content=$($script_dir/create_backend_tf.sh $ENVIRONMENT $STAGE_NAME $APPLICATION)
backend_tf_content_creation_exit_code=$?


# Check for GitHub IdP in AWS
github_idp_exists=$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?contains(Arn, 'github')]" --output json | jq '.[].Arn' | tr -d '"')

if [ -z "$github_idp_exists" ]; then
    echo "GitHub Identity Provider does not exist in AWS."

    # Prompt user to create the IdP
    read -p "Do you want to create the GitHub Identity Provider? (y/n): " user_input
    
    if [[ "$user_input" == "yes" || "$user_input" == "y" || "$user_input" == "Y" ]]; then
        idp_create_choice=true
    else
        idp_create_choice=false
        echo "CICD will not work. Create the Github IdP separately."
    fi
else
    echo "GitHub Identity Provider already exists in AWS."
    idp_create_choice=false
fi


echo
echo "Create $STAGE_DIR."
echo "Create resources in AWS region: $REGION"
echo "Create state S3 bucket and Dynamodb table for synchronization if necessary."
echo "Create Github IdP in AWS: $idp_create_choice"
echo "Create CICD IAM role in AWS for repo: $REPO_URL"
read -p "Do you want to continue? (y/n) " choice

case "$choice" in 
    y|Y ) echo "Continuing...";;
    n|N ) echo "Exiting."; exit 0;;
    * ) echo "Invalid input. Exiting."; exit 1;;
esac



# Create the directory if it does not exist
mkdir -p "$STAGE_DIR"


relative_path_to_modules="../../../.."

if [ ! -f "$STAGE_DIR/providers.tf" ]; then
cat <<EOF > "$STAGE_DIR/providers.tf"
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = local.region
}
EOF
fi

if [ ! -f "$STAGE_DIR/main.tf" ]; then
# backend_tf_content_creation_exit_code is 1 if there is no remote state management
# and 0 if there is
# we  abuse the exit code for the count/conditional module creation of the remote state
cat <<EOF > "$STAGE_DIR/main.tf"
locals {
  region = "$REGION"
  tags   = {
    Environment = "$ENVIRONMENT"
    Terraform   = "true"
    Application = "$APPLICATION"
    Repository  = "$REPO_URL"
    Stage       = "$STAGE_NAME"
  }
}

module "tf_remote_state" {
  source         = "$relative_path_to_modules/modules/tf_remote_state"
  count          = $backend_tf_content_creation_exit_code
  region         = local.region
  tags           = local.tags
  bucket_name    = "tf-state-$ENVIRONMENT"
  dynamodb_table = "tf-state-locks-$ENVIRONMENT"
  force_destroy  = true
}

module "cicd" {
  source               = "$relative_path_to_modules/modules/cicd"
  region               = local.region
  tags                 = local.tags
  create_provider      = $idp_create_choice
  subjects             = ["repo:$ORIGIN_REPO:*"]
  name                 = "$REPO_NAME-$ENVIRONMENT-cicd-role"
  max_session_duration = 3600
}
EOF
fi

if [ ! -f "$STAGE_DIR/outputs.tf" ]; then

cat <<EOF > "$STAGE_DIR/outputs.tf"
output "state_bucket_name" {
  value = try(module.tf_remote_state[0].bucket_name, null)
}

output "state_lock_table_name" {
  value = try(module.tf_remote_state[0].dynamodb_table_name, null)
}

output "cicd_role_arn" {
  description = "ARN of AWS IAM role for CICD"
  value       = module.cicd.role_arn
}

output "cicd_role_name" {
  description = "Name of IAM role"
  value       = module.cicd.role_name
}

output "cicd_provider_arn" {
  description = "The ARN assigned by AWS for this provider"
  value       = try(module.cicd.provider_arn, null)
}
EOF
fi

if [ "$backend_tf_content_creation_exit_code" -eq "0" ]; then
  echo "$backend_tf_content" > "$STAGE_DIR/backend.tf"
fi



# Navigate to the directory
cd "$STAGE_DIR"

# Initialize Terraform
terraform init -migrate-state

# Plan Terraform changes
terraform plan -out tfplan
status=$?

# Handle the exit status
if [ $status -ne 0 ]; then
    echo "Error during terraform plan. Exiting." >&2
    exit 1
fi

# Apply Terraform changes
terraform apply -auto-approve tfplan
status=$?

# Handle the exit status
if [ $status -ne 0 ]; then
    echo "Error during terraform apply. Exiting." >&2
    exit 1
fi

# Capture the output from the tf_remote_state module
json_output=$(get_tf_remote_state_infra)
# Parse the JSON output
s3_bucket=$(echo "$json_output" | jq -r '.s3_bucket')
dynamodb_table=$(echo "$json_output" | jq -r '.dynamodb_table')
role_arn=$(terraform output -raw cicd_role_arn)

# Output the values
echo "S3 State Bucket Name: $bucket_name"
echo "S3 State Lock DynamoDB Table Name: $dynamodb_table_name"
echo "CICD GitHub role with access to AWS: $role_arn"
echo "Region: $REGION"
echo
  

echo "Create a backend configuration file for remote state using"
echo "$script_dir/create_backend_tf.sh $ENVIRONMENT $STAGE_NAME $APPLICATION"

# Create a backend configuration file for remote state
# be careful you are in the $STAGE_DIR already
if [ $backend_tf_content_creation_exit_code -ne 0 ]; then
  backend_tf_content=$($script_dir/create_backend_tf.sh $ENVIRONMENT $STAGE_NAME $APPLICATION)
  backend_tf_content_creation_exit_code=$?
  if [ $backend_tf_content_creation_exit_code -ne 0 ]; then
    echo "Error creating backend.tf for remote state tracking. Leaving only local state." >&2
    exit 1
  fi
  echo "$backend_tf_content" > "$STAGE_DIR/backend.tf"

  # Reinitialize Terraform with the new backend configuration
  terraform init -migrate-state

  # Output success message
  echo "Terraform state has been migrated to the remote S3 backend."
fi