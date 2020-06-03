variable "release-version" {
  type = string
  description = "The release version to deploy"
}
variable "github-owner" {
    type = string
    description = "The github owner of the repo where the release has been made"
}
variable "github-repo" {
    type = string
    description = "The github repo name where the release has been made"
}
variable "deployable-name" {
    type = string
    description = "The name of the deployable file"
}
variable "bucket-name" {
    type = string
    description = "The name to use for the bucket"
}