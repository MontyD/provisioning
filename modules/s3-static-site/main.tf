provider "aws" {
  region = var.region
}

data "external" "release-resources" {
  program = ["node", "${path.module}/scripts/fetch-resources.js"]
  query = {
    owner = var.github-owner
    repo = var.github-repo
    version = var.release-version
    deployableName = var.deployable-name
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.domain
  acl    = "public-read"
  website {
    index_document = "index.html"
  }
}

// Todo - mime types, fix race condition with apply
resource "aws_s3_bucket_object" "website_files" {
  for_each   = fileset(data.external.release-resources.result, "**/*.*")
  bucket     = aws_s3_bucket.bucket.bucket
  key        = replace(each.value, "${data.external.release-resources.result}/dist", "")
  source     = "${data.external.release-resources.result}/dist/${each.value}"
  acl        = "public-read"
  etag       = filemd5("${data.external.release-resources.result}/dist/${each.value}")
}
