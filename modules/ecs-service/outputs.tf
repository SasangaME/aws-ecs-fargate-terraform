output "service_name" {
  value = aws_ecs_service.main.name
}

output "task_security_group_id" {
  value = aws_security_group.ecs_tasks.id
}
