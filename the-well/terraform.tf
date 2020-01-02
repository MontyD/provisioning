terraform {
  backend "s3" {
    bucket = "the-well-state"
    key    = "terraform.tfstate"
    region = "eu-west-2"
  }
}

module "s3-static-site" {
  source          = "../modules/s3-static-site"
  region          = "eu-west-2"
  domain          = var.domain
  release-version = var.release-version
  github-owner    = var.github-owner
  github-repo     = var.github-repo
  deployable-name = var.deployable-name
}
