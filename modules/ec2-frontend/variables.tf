variable "aws_region" {
  description = "AWS region to deploy"
  default     = "eu-central-1"
}

variable "websocket_url" {
  description = "WebSocket URL"
  type        = string
}

variable "api_host" {
  description = "API Host"
  type        = string
}

variable "docker_username" {
  description = "Docker username"
  type        = string
}

variable "docker_password" {
  description = "Docker password"
  type        = string
}