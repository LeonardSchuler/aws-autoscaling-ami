output "role_arn" {
  description = "ARN of IAM role"
  value       = try(module.iam_github_oidc_role.arn, null)
}

output "role_name" {
  description = "Name of IAM role"
  value       = try(module.iam_github_oidc_role.name, null)
}

output "provider_arn" {
  description = "The ARN assigned by AWS for this provider"
  value       = try(module.iam_github_oidc_provider.arn, null)
}
