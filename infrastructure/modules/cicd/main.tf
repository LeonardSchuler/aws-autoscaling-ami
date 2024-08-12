module "iam_github_oidc_provider" {
  source = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"
  create = var.create_provider
}

module "iam_github_oidc_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"

  # This should be updated to suit your organization, repository, references/branches, etc.
  subjects             = var.subjects
  name_prefix          = var.name
  max_session_duration = var.max_session_duration

  policies = var.policies
  tags     = var.tags
}
