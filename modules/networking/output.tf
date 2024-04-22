output "subnet_ids" {
  description = "List of IDs of selected subnets"
  value       = [for s in data.aws_subnet.selected : s.id]
}

output "vpc_id" {
  description = "The ID of the selected VPC"
  value       = data.aws_vpc.selected.id
}
