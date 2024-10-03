variable "aws_region" {
  description = "AWS region to deploy"
  default     = "eu-central-1"
}

variable "access_token_repo" {
  description = "Access token for the repository"
  type        = string
}
