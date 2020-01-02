provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.domain
  acl    = "public-read"
  website {
    index_document = "index.html"
  }
}

variable "temp" {
  default = "./.assets-temp"
}
variable "deployable" {
  default = "deployable"
}

resource "null_resource" "local-resources" {
  triggers = {
    versions-to-deploy = var.release-version
  }

  provisioner "local-exec" {
    command = <<EOT
      rm -rf ${var.temp};
      mkdir -P ${var.temp};
      wget https://github.com/${var.github-owner}/${var.github-repo}/releases/download/${var.release-version}/${var.deployable-name} -P ${var.temp};
      tar -czvf ${var.temp}/${var.deployable-name} ${var.temp}/${var.deployable}
    EOT
  }
}



resource "aws_s3_bucket_object" "website_files" {
  for_each   = fileset("${var.temp}/${var.deployable}", "**/*.*")
  bucket     = aws_s3_bucket.bucket.bucket
  key        = replace(each.value, "${var.temp}/${var.deployable}", "")
  source     = "${var.temp}/${var.deployable}/${each.value}"
  acl        = "public-read"
  etag       = filemd5("${var.temp}/${var.deployable}/${each.value}")
  depends_on = [null_resource.local-resources]
}
