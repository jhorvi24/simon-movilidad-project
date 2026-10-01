output "github_actions_role_arn" {
  description = "ARN del rol que GitHub Actions asume vía OIDC. Usar en el workflow (role-to-assume)."
  value       = aws_iam_role.github_actions.arn
}

output "oidc_provider_arn" {
  description = "ARN del OIDC provider de GitHub (creado o existente)."
  value       = local.oidc_provider_arn
}

output "ecs_execution_role_arn" {
  description = "ARN del execution role de ECS."
  value       = aws_iam_role.ecs_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN del task role de ECS (runtime de la app)."
  value       = aws_iam_role.ecs_task.arn
}
