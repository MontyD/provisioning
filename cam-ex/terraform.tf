terraform {
  backend "s3" {
    bucket = "cam-ex-state"
    key    = "terraform.tfstate"
    region = "eu-west-2"
  }
}

module "s3-site" {
  source          = "../modules/s3-static-site"
  region          = "eu-west-2"
  bucket-name     = var.bucket-name
  release-version = var.release-version
  github-owner    = var.github-owner
  github-repo     = var.github-repo
  deployable-name = var.deployable-name
}
