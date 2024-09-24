variable "aws_region" {
  description = "AWS region to deploy"
  default     = "eu-central-1"
}

variable "ecr_image_url" {
  description = "The ECR repository URL for the image"
  type        = string
}

variable "db_user" {
  description = "The username for the database"
  type        = string
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  sensitive   = true
}

variable "port" {
  description = "port the backend runs"
  type        = string
}

variable "node_env" {
  description = "environment of the app"
  type        = string
}

variable "access_token" {
  description = "access token for user authentication"
  type        = string
}

variable "refresh_token" {
  description = "refresh token for user authentication"
  type        = string
}
