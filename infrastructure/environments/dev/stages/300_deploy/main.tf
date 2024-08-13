locals {
  region = "eu-central-1"
  network = {
    name               = "$APPLICATION"
    azs                = ["${local.region}a", "${local.region}b", "${local.region}c"]
    cidr               = "10.0.0.0/16"
    private_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
    public_subnets     = ["10.0.101.0/24", "10.0.102.0/24"]
    enable_nat_gateway = false
  }
  tags = {
    Environment = "dev"
    Terraform   = "true"
    Application = "aws-autoscaling-ami"
    Repository  = "https://github.com/LeonardSchuler/aws-autoscaling-ami"
    Stage       = "300_deploy"
  }
}
module "vpc" {
  source             = "../../../../modules/vpc"
  tags               = local.tags
  name               = local.network["name"]
  cidr               = local.network["cidr"]
  azs                = local.network["azs"]
  private_subnets    = local.network["private_subnets"]
  public_subnets     = local.network["public_subnets"]
  enable_nat_gateway = local.network["enable_nat_gateway"]
}
