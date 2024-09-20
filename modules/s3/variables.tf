variable "bucket_name" {
  description = "The name of the S3 bucket to store the Terraform state"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy"
  default     = "eu-central-1"
}

variable "git_sha" {
  type = string
}