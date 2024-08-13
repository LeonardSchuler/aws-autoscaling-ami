locals {
  region = "eu-central-1"
  tags   = {
    Environment = "dev"
    Terraform   = "true"
    Application = "aws-autoscaling-ami"
    Repository  = "https://github.com/LeonardSchuler/aws-autoscaling-ami"
    Stage       = "000_init"
  }
}

module "tf_remote_state" {
  source         = "../../../../modules/tf_remote_state"
  count          = 1
  region         = local.region
  tags           = local.tags
  bucket_name    = "tf-state-dev"
  dynamodb_table = "tf-state-locks-dev"
  force_destroy  = true
}

module "cicd" {
  source               = "../../../../modules/cicd"
  region               = local.region
  tags                 = local.tags
  create_provider      = true
  subjects             = ["repo:LeonardSchuler/aws-autoscaling-ami:*"]
  name                 = "aws-autoscaling-ami-dev-cicd-role"
  max_session_duration = 3600
}
