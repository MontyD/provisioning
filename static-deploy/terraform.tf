provider "aws" {
    region = "eu-west-2"
}

terraform {
  backend "s3" {
    bucket = "static-deploy-state"
    key    = "terraform.tfstate"
    region = "eu-west-2"
  }
}
resource "aws_s3_bucket" "bucket" {
    bucket = "montydawson.com"
    acl    = "public-read"
    website {
        index_document = "index.html"
    }
}
