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