terraform {
  backend "s3" {
    bucket = "monty-dawson-state"
    key    = "terraform.tfstate"
    region = "eu-west-2"
  }
}

module "cloudfront-site" {
  source          = "../modules/cloudfront-site"
  region          = "eu-west-2"
  domain          = var.domain
  release-version = var.release-version
  github-owner    = var.github-owner
  github-repo     = var.github-repo
  deployable-name = var.deployable-name
}
