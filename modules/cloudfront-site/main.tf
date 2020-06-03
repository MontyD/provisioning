provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "east"
  region = "us-east-1"
}

module "s3-static-site" {
  source          = "../s3-static-site"
  region          = var.region
  bucket-name     = var.domain
  release-version = var.release-version
  github-owner    = var.github-owner
  github-repo     = var.github-repo
  deployable-name = var.deployable-name
}

resource "aws_acm_certificate" "certificate" {
  provider                  = aws.east // required for the certificate to be picked up by cloudfront
  domain_name               = var.domain
  validation_method         = "DNS"
  subject_alternative_names = ["www.${var.domain}"]
}

resource "aws_cloudfront_distribution" "cdn_distribution" {
  origin {
    domain_name = module.s3-static-site.hosting_bucket.bucket_domain_name
    origin_id   = var.domain
  }

  logging_config {
    include_cookies = false
    bucket          = module.s3-static-site.log_bucket.bucket_domain_name
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
    response_code      = contains(values(module.s3-static-site.website_files), "error.html") ? 404 : 200
    response_page_path = contains(values(module.s3-static-site.website_files), "error.html") ? "/error.html" : "/index.html"
  }
}
