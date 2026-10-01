output "ecs_execution_role_arn" {
  description = "ARN del execution role de ECS."
  value       = aws_iam_role.ecs_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN del task role de ECS (runtime de la app)."
  value       = aws_iam_role.ecs_task.arn
}
