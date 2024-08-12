resource "random_string" "name_suffix" {
  length  = 16
  upper   = false
  special = false
}

resource "aws_s3_bucket" "terraform_state" {
  bucket        = "${var.bucket_name}-${random_string.name_suffix.result}"
  force_destroy = var.force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {

  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id = "version-cleanup"

    noncurrent_version_expiration {
      noncurrent_days = 60
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    status = "Enabled"
  }

  rule {
    id = "delete-incomplete-multipart-uploads"
    abort_incomplete_multipart_upload {
      days_after_initiation = 5
    }
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.dynamodb_table}-${random_string.name_suffix.result}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = var.tags
}
