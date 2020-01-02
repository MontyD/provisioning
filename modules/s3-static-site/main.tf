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
  default = ".temp"
}

resource "null_resource" "local-resources" {
  triggers = {
    versions-to-deploy = var.release-version
    bucket = aws_s3_bucket.bucket.id
  }

  provisioner "local-exec" {
    command = "rm -rf ${path.module}/${var.temp} && mkdir -p ${path.module}/${var.temp}"
    interpreter = ["bash", "-c"]
  }
  provisioner "local-exec" {
    command = "wget -q https://github.com/${var.github-owner}/${var.github-repo}/releases/download/${var.release-version}/${var.deployable-name} -P ${path.module}/${var.temp}"
    interpreter = ["bash", "-c"]
  }
  provisioner "local-exec" {
    command = "tar -xf ${path.module}/${var.temp}/${var.deployable-name} --directory ${path.module}/${var.temp}"
    interpreter = ["bash", "-c"]
  }
}

// Todo - mime types, fix race condition with apply
resource "aws_s3_bucket_object" "website_files" {
  for_each   = fileset("${path.module}/${var.temp}/dist", "**/*.*")
  bucket     = aws_s3_bucket.bucket.bucket
  key        = replace(each.value, "${path.module}/${var.temp}/dist", "")
  source     = "${path.module}/${var.temp}/dist/${each.value}"
  acl        = "public-read"
  etag       = filemd5("${path.module}/${var.temp}/dist/${each.value}")
  depends_on = [null_resource.local-resources]
}
