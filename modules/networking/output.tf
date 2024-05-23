output "public_subnet_ids" {
  description = "The IDs of the subnet"
  value       = aws_subnet.public_ecs_subnet[*].id
}

output "private_subnet_ids" {
  description = "The IDs of the subnet"
  value       = aws_subnet.private_ecs_subnet[*].id
}
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.ecs_vpc.id
}

