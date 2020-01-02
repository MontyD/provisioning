terraform {
  required_version = ">= 0.12"
}

provider "aws" {
    region = var.region
}
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_id
  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}