provider "aws" {
  region = var.region
}

data "external" "release-resources" {
  program = ["node", "${path.module}/scripts/fetch-resources.js"]
  query = {
    owner          = var.github-owner
    repo           = var.github-repo
    version        = var.release-version
    deployableName = var.deployable-name
  }
}

data "external" "content-types" {
  program = ["node", "${path.module}/scripts/get-content-types.js"]
  query = data.external.release-resources.result
}

resource "aws_s3_bucket" "web-bucket" {
  bucket = var.bucket-name
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = contains(values(data.external.release-resources.result), "error.html") ? "error.html" : "index.html"
    routing_rules = contains(values(data.external.release-resources.result), "route-rules.json") ? file(element(keys(data.external.release-resources.result), index(values(data.external.release-resources.result), "route-rules.json"))) : null
  }
}

resource "aws_s3_bucket" "logs-bucket" {
  bucket        = "logs-${var.bucket-name}"
  acl           = "private"
  force_destroy = true

  tags = {
    Name = "Logs"
  }
}

resource "aws_s3_bucket_object" "website_files" {
  for_each     = data.external.release-resources.result
  bucket       = aws_s3_bucket.web-bucket.bucket
  key          = each.key
  source       = each.value
  acl          = "public-read"
  etag         = filemd5(each.value)
  content_type = data.external.content-types.result[each.key]
}
