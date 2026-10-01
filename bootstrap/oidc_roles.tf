###############################################################################
# Roles de deploy OIDC (dev y prod)
#
# Viven aqui, en el bootstrap, porque son IDENTIDAD (IAM), no infraestructura
# de app. Crearlos NO aprovisiona VPC/ECS/ALB ni genera costo recurrente.
#
# Flujo huevo-gallina resuelto: corres el bootstrap UNA vez (barato), quedan
# los roles, y el pipeline usa esos roles para crear toda la infra de la app.
#
# El OIDC provider de GitHub ya existe en la cuenta; se referencia por su ARN
# deterministico (no se crea aqui para no chocar con el existente).
###############################################################################

locals {
  oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

module "deploy_role_dev" {
  source = "../modulos/github-oidc-role"

  name_prefix       = "${var.project_name}-dev"
  project_name      = var.project_name
  oidc_provider_arn = local.oidc_provider_arn
  github_repository = var.github_repository
  github_subject_claims = [
    "environment:dev",
    "ref:refs/heads/main",
    "pull_request",
  ]
  state_bucket_arn = aws_s3_bucket.tfstate["dev"].arn
}

module "deploy_role_prod" {
  source = "../modulos/github-oidc-role"

  name_prefix       = "${var.project_name}-prod"
  project_name      = var.project_name
  oidc_provider_arn = local.oidc_provider_arn
  github_repository = var.github_repository
  github_subject_claims = [
    "environment:prod",
  ]
  state_bucket_arn = aws_s3_bucket.tfstate["prod"].arn
}
