output "rds_endpoint" {
  value = aws_db_instance.resume_db_instance.endpoint
}

output "rds_db_name" {
  value = aws_db_instance.resume_db_instance.db_name
}

output "rds_private_address" {
  description = "The private IP address of the RDS instance"
  value       = aws_db_instance.resume_db_instance.address
}

output "rds_private_ip" {
  description = "The private IP address of the RDS instance"
  value       = aws_db_instance.resume_db_instance.id
}


