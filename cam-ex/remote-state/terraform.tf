module "s3-remote-state-bucket" {
  source = "../../modules/s3-backend"
  region = "eu-west-2"
  bucket_id = "cam-ex-state"
}
