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
