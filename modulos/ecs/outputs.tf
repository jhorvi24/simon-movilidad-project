output "cluster_name" {
  description = "Nombre del cluster ECS."
  value       = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  description = "ARN del cluster ECS."
  value       = aws_ecs_cluster.this.arn
}

output "service_name" {
  description = "Nombre del servicio ECS."
  value       = aws_ecs_service.this.name
}

output "task_definition_arn" {
  description = "ARN de la task definition."
  value       = aws_ecs_task_definition.this.arn
}

output "log_group_name" {
  description = "Nombre del log group de CloudWatch del servicio."
  value       = aws_cloudwatch_log_group.this.name
}
