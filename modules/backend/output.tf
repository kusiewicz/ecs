output "ecr_repository_arn" {
  description = "The ARN of the ECR repository"
  value       = aws_ecr_repository.app.arn
}

output "ecs_task_arn" {
  description = "The ARN of the ECS task"
  value       = aws_ecs_task_definition.task.arn
}

output "ecs_security_group_id" {
  description = "The ID of the ECS security group"
  value       = aws_security_group.ecs.id
}

