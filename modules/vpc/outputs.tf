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

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.resume_main_vpc.cidr_block
}

# Output for Public Subnet CIDR Blocks
output "public_subnet_cidr_block_1a" {
  description = "Public subnet 1a CIDR block"
  value       = aws_subnet.public_subnet_1a.cidr_block
}

output "public_subnet_cidr_block_1b" {
  description = "Public subnet 1b CIDR block"
  value       = aws_subnet.public_subnet_1b.cidr_block
}

output "public_subnet_cidr_block_1c" {
  description = "Public subnet 1c CIDR block"
  value       = aws_subnet.public_subnet_1c.cidr_block
}

# Output for Private Subnet CIDR Blocks
output "private_subnet_cidr_block_1a" {
  description = "Private subnet 1a CIDR block"
  value       = aws_subnet.private_subnet_1a.cidr_block
}

output "private_subnet_cidr_block_1b" {
  description = "Private subnet 1b CIDR block"
  value       = aws_subnet.private_subnet_1b.cidr_block
}

output "private_subnet_cidr_block_1c" {
  description = "Private subnet 1c CIDR block"
  value       = aws_subnet.private_subnet_1c.cidr_block
}
