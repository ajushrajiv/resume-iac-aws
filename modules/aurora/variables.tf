variable "aws_region" {
  description = "AWS region to deploy"
  default     = "eu-central-1"
}

variable "db_master_username" {
  description = "The master username for the Aurora database"
  type        = string
}

variable "db_master_password" {
  description = "The master password for the Aurora database"
  type        = string
  sensitive   = true
}
