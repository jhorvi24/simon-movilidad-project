output "role_arn" {
  description = "ARN del rol que GitHub Actions asume via OIDC."
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Nombre del rol de deploy."
  value       = aws_iam_role.this.name
}
