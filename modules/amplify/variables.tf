variable "aws_region" {
  description = "AWS region to deploy"
  default     = "eu-central-1"
}

variable "repo_name" {
  description = "The name of the repository"
  type        = string
}

variable "access_token_repo" {
  description = "Access token for the repository"
  type        = string
}
