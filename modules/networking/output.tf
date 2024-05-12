output "subnet_ids" {
  description = "List of IDs of subnets"
  value       = aws_subnet.ecs_subnet[*].id
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.ecs_vpc.id
}
