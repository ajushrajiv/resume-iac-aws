output "instance_public_ip" {
  description = "Public ip of the ec2 instance"
  value       = aws_instance.backend_instance.id
}

output "rds_private_address" {
  value = data.terraform_remote_state.rds-sql.outputs.rds_private_address
}