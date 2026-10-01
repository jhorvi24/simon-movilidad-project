###############################################################################
# Composicion del ambiente PROD
#
# Igual que dev pero endurecido para produccion:
#   - NAT Gateway por AZ (alta disponibilidad)
#   - ECR con tags IMMUTABLE (trazabilidad del supply chain)
#   - ALB con proteccion de borrado
#   - Mas CPU/memoria y mayor rango de autoscaling
#   - NO crea el OIDC provider (lo reutiliza del creado en dev)
###############################################################################

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  name_prefix = "${var.project_name}-prod"

  container_image = var.container_image != "" ? var.container_image : "public.ecr.aws/nginx/nginx:stable-alpine"

  # ARN deterministico del OIDC provider de GitHub creado en dev.
  oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

module "networking" {
  source = "../../modulos/networking"

  name_prefix        = local.name_prefix
  vpc_cidr           = var.vpc_cidr
  container_port     = var.container_port
  single_nat_gateway = false # prod: NAT por AZ (HA)
}

module "iam" {
  source = "../../modulos/iam"

  name_prefix                = local.name_prefix
  project_name               = var.project_name
  create_oidc_provider       = false # reutiliza el provider creado en dev
  existing_oidc_provider_arn = local.oidc_provider_arn
  github_repository          = var.github_repository
  github_subject_claims = [
    "environment:prod",
  ]
  state_bucket_arn = "arn:aws:s3:::simon-movilidad-tfstate-prod-${data.aws_caller_identity.current.account_id}"
}

module "ecr" {
  source = "../../modulos/ecr"

  repository_name      = "${var.project_name}-app-prod"
  image_tag_mutability = "IMMUTABLE" # prod: una tag no se sobreescribe
  force_delete         = false
  max_image_count      = 20
}

module "alb" {
  source = "../../modulos/alb"

  name_prefix                = local.name_prefix
  vpc_id                     = module.networking.vpc_id
  public_subnet_ids          = module.networking.public_subnet_ids
  alb_security_group_id      = module.networking.alb_security_group_id
  container_port             = var.container_port
  health_check_path          = "/health"
  enable_deletion_protection = true
}

module "ecs" {
  source = "../../modulos/ecs"

  name_prefix              = local.name_prefix
  aws_region               = var.aws_region
  private_subnet_ids       = module.networking.private_subnet_ids
  tasks_security_group_id  = module.networking.tasks_security_group_id
  execution_role_arn       = module.iam.ecs_execution_role_arn
  task_role_arn            = module.iam.ecs_task_role_arn
  container_name           = "app"
  container_image          = local.container_image
  container_port           = var.container_port
  readonly_root_filesystem = true
  target_group_arn         = module.alb.target_group_arn

  # prod: recursos mayores y escalado amplio
  task_cpu                 = 512
  task_memory              = 1024
  desired_count            = 2
  autoscaling_min_capacity = 2
  autoscaling_max_capacity = 10
  cpu_target_value         = 55
  memory_target_value      = 65
}
