output "bucket_name" {
  value = try(aws_s3_bucket.terraform_state.bucket, null)
}

output "dynamodb_table_name" {
  value = try(aws_dynamodb_table.terraform_locks.name, null)
}

output "region" {
  value = try(var.region, null)
}
