variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
}

variable "create_provider" {
  description = "Create the provider, fails if the provider already exists. Role will be generated anyway."
  type        = bool
  default     = false
}

# See: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_oidc.html#idp_oidc_Create_GitHub
# Examples
# Branch: 'repo:yourgithubuser/yourgithubrepo:ref:refs/heads/yourbranch
# All branches in repo: 'repo:yourgithubuser/yourgithubrepo:*'
variable "subjects" {
  description = "List of GitHub OIDC subjects that are permitted by the trust policy. You do not need to prefix with `repo:` as this is provided. Example: `['my-org/my-repo:*', 'my-org/my-repo:ref:refs/heads/main']`"
  type        = list(string)
  default     = []
}

variable "name" {
  description = "IAM role name prefix"
  type        = string
}

variable "policies" {
  description = "Policies to attach to the IAM role in `{'static_name' = 'policy_arn'}` format"
  type        = map(string)
  default = {
    Admin = "arn:aws:iam::aws:policy/AdministratorAccess"
  }
}

variable "max_session_duration" {
  description = "Maximum CLI/API session duration in seconds between 3600 and 43200"
  type        = number
  default     = 3600 # 1 hour
}
