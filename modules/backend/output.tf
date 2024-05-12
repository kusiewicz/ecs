output "ecr_repository_arn" {
  description = "The ARN of the ECR repository"
  value       = aws_ecr_repository.app.arn
}

output "ecs_task_arn" {
  description = "The ARN of the ECS task"
  value       = aws_ecs_task_definition.task.arn
}
