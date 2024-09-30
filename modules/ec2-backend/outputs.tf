output "instance_public_id" {
  description = "Public ip of the ec2 instance"
  value       = aws_instance.backend_instance.id
}

output "instance_public_ip" {
  description = "Public ip of the ec2 instance"
  value       = aws_instance.backend_instance.public_ip
}

