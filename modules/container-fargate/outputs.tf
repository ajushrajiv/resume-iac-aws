output "ecs_service_public_ip" {
  description = "Public IP address of the ECS service"
  value       = aws_ecs_service.resume_service.network_configuration[0].assign_public_ip
}
