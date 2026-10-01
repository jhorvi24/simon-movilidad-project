###############################################################################
# Composicion del ambiente DEV
#
# Cablea todos los modulos: networking -> iam -> ecr -> alb -> ecs.
# El flujo del trafico: Internet -> ALB(80) -> tareas ECS(8080) en subnets
# privadas.
###############################################################################

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  name_prefix = "${var.project_name}-dev"

  # Si no se pasa una imagen (primer apply), usa un placeholder publico para que
  # el servicio ECS arranque. El pipeline luego pasa la URL real de ECR + tag.
  container_image = var.container_image != "" ? var.container_image : "public.ecr.aws/nginx/nginx:stable-alpine"
}

module "networking" {
  source = "../../modulos/networking"

  name_prefix        = local.name_prefix
  vpc_cidr           = var.vpc_cidr
  container_port     = var.container_port
  single_nat_gateway = true # dev: un solo NAT para ahorrar costos
}

module "iam" {
  source = "../../modulos/iam"

  name_prefix          = local.name_prefix
  project_name         = var.project_name
  create_oidc_provider = true # dev crea el OIDC provider (uno por cuenta)
  github_repository    = var.github_repository
  github_subject_claims = [
    "environment:dev",
    "ref:refs/heads/main",
    "pull_request",
  ]
  state_bucket_arn = "arn:aws:s3:::simon-movilidad-tfstate-dev-${data.aws_caller_identity.current.account_id}"
}

module "ecr" {
  source = "../../modulos/ecr"

  repository_name      = "${var.project_name}-app"
  image_tag_mutability = "MUTABLE" # dev: permite reusar tags
  force_delete         = true
  max_image_count      = 10
}

module "alb" {
  source = "../../modulos/alb"

  name_prefix                = local.name_prefix
  vpc_id                     = module.networking.vpc_id
  public_subnet_ids          = module.networking.public_subnet_ids
  alb_security_group_id      = module.networking.alb_security_group_id
  container_port             = var.container_port
  health_check_path          = "/health"
  enable_deletion_protection = false
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

  # dev: recursos pequenos y escalado modesto
  task_cpu                 = 256
  task_memory              = 512
  desired_count            = 1
  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 3
}
