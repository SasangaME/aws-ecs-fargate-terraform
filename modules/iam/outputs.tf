output "execution_role_arn" {
  value       = aws_iam_role.ecs_execution_role.arn
  description = "Execution role ARN for the ECS Fargate cluster"
}

output "task_role_arn" {
  value       = aws_iam_role.ecs_task_role.arn
  description = "Task role ARN for our Fargate service"
}

output "execution_role_name" {
  value = aws_iam_role.ecs_execution_role.name
}

output "task_role_name" {
  value = aws_iam_role.ecs_task_role.name
}
