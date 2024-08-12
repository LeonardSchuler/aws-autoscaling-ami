variable "region" {
  description = "The AWS region"
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
}

variable "bucket_name" {
  description = "The name of the S3 bucket to create (will append a random suffix for uniqueness)"
}

variable "dynamodb_table" {
  description = "The name of the DynamoDB table to create (will append a random suffix for uniqueness)"
}

variable "force_destroy" {
  description = "Controls if state bucket can be deleted even if it still contains state files"
  type        = bool
  default     = false
}
