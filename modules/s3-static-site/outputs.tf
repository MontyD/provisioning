output "website_files" {
  value       = data.external.release-resources.result
  description = "The website files hosted in the s3 bucket."
}

output "hosting_bucket" {
    value = aws_s3_bucket.web-bucket
    description = "The bucket where the static assets are hosted"
}

output "log_bucket" {
    value = aws_s3_bucket.logs-bucket
    description = "The bucket where the logs will be stored"
}