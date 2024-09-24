output "rds_endpoint" {
  value = aws_db_instance.resume_db_instance.endpoint
}

output "rds_db_name" {
  value = aws_db_instance.resume_db_instance.db_name
}
