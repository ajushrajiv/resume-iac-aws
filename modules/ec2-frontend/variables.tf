variable "aws_region" {
  description = "AWS region to deploy"
  default     = "eu-central-1"
}

variable "websocket_url" {
  description = "WebSocket URL"
  default     = resume-backend-lb-94904934.eu-central-1.elb.amazonaws.com
}

variable "api_host" {
  description = "API Host"
  default     = resume-backend-lb-94904934.eu-central-1.elb.amazonaws.com
}

variable "docker_username" {
  description = "Docker username"
  type        = string
}

variable "docker_password" {
  description = "Docker password"
  type        = string
}