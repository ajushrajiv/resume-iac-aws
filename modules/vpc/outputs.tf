output "vpc_id" {
  value = aws_vpc.resume_main_vpc.id
}

output "public_subnet_id_1a" {
  value = aws_subnet.public[0].id
}

output "public_subnet_id_1b" {
  value = aws_subnet.public[1].id
}

output "public_subnet_id_1c" {
  value = aws_subnet.public[2].id
}

output "private_subnet_id_1a" {
  value = aws_subnet.private[0].id
}

output "private_subnet_id_1b" {
  value = aws_subnet.private[1].id
}

output "private_subnet_id_1c" {
  value = aws_subnet.private[2].id
}