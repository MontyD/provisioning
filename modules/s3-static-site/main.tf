provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "east"
  region = "us-east-1"
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

resource "aws_s3_bucket" "web-bucket" {
  bucket = var.domain
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = contains(keys(data.external.release-resources.result), "error.html") ? "error.html" : "index.html"
  }
}

resource "aws_s3_bucket" "logs-bucket" {
  bucket        = "logs-${var.domain}"
  acl           = "private"
  force_destroy = true

  tags = {
    Name = "Logs"
  }
}

resource "aws_s3_bucket_object" "website_files" {
  for_each     = data.external.release-resources.result
  bucket       = aws_s3_bucket.web-bucket.bucket
  key          = replace(replace(each.key, data.external.release-resources.result.__tempDir, ""), data.external.release-resources.result.__pathSep, "/")
  source       = substr(each.key, 0, 2) == "__" ? "" : each.key
  acl          = "public-read"
  etag         = substr(each.key, 0, 2) == "__" ? "" : filemd5(each.key)
  content_type = substr(each.key, 0, 2) == "__" ? "" : each.value
}

resource "aws_acm_certificate" "certificate" {
  provider                  = aws.east // required for the certificate to be picked up by cloud-front
  domain_name               = var.domain
  validation_method         = "DNS"
  subject_alternative_names = ["www.${var.domain}"]
}

resource "aws_cloudfront_distribution" "cdn_distribution" {
  origin {
    domain_name = aws_s3_bucket.web-bucket.bucket_domain_name
    origin_id   = var.domain
  }

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.logs-bucket.bucket_domain_name
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = var.domain
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  aliases = ["www.${var.domain}", var.domain]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.certificate.arn
    ssl_support_method  = "sni-only"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = contains(keys(data.external.release-resources.result), "error.html") ? "/error.html" : "/index.html"
  }
}
