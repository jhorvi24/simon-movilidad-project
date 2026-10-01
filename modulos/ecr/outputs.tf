output "repository_url" {
  description = "URL del repositorio ECR (usar como base de la imagen en el task definition y en el push del pipeline)."
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "ARN del repositorio ECR."
  value       = aws_ecr_repository.this.arn
}

output "repository_name" {
  description = "Nombre del repositorio ECR."
  value       = aws_ecr_repository.this.name
}
