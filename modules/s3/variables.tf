variable "aws_region" {
  description = "AWS region to deploy"
  default     = "eu-central-1"
}

variable "git_sha" {
  description = "The random name of the S3 bucket generated to store the Terraform state"
  type        = string
}
