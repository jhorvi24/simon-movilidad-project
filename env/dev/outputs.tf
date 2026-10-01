output "alb_url" {
  description = "URL publica de la app (HTTP)."
  value       = "http://${module.alb.alb_dns_name}"
}

output "ecr_repository_url" {
  description = "URL del repositorio ECR para push de imagenes."
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "Nombre del cluster ECS."
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Nombre del servicio ECS."
  value       = module.ecs.service_name
}

output "github_actions_role_arn" {
  description = "ARN del rol que asume GitHub Actions via OIDC."
  value       = module.iam.github_actions_role_arn
}
