###############################################################################
# Bootstrap del estado remoto de Terraform
#
# Este stack se ejecuta UNA SOLA VEZ y con estado LOCAL, porque su trabajo es
# crear el bucket de S3 donde el resto de los stacks guardaran su estado remoto.
# (No se puede guardar el estado del bucket dentro del bucket que aun no existe).
#
# Crea un bucket de estado por ambiente (dev y prod) con:
#   - Versionado (recuperacion ante corrupcion/borrado del state)
#   - Cifrado en reposo (SSE)
#   - Bloqueo total de acceso publico
#   - Ownership enforced (sin ACLs)
#
# El bloqueo de estado se hace con lockfile NATIVO de S3 (use_lockfile = true),
# disponible desde Terraform >= 1.10, por lo que NO se necesita DynamoDB.
###############################################################################

terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
      Component = "tfstate-bootstrap"
    }
  }
}

locals {
  # Un bucket de estado por ambiente. El sufijo con account_id evita colisiones
  # de nombres globales de S3 entre cuentas.
  environments = toset(["dev", "prod"])
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "tfstate" {
  for_each = local.environments

  bucket = "${var.project_name}-tfstate-${each.key}-${data.aws_caller_identity.current.account_id}"

  # Proteccion contra destroy accidental del bucket de estado.
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "${var.project_name}-tfstate-${each.key}"
    Environment = each.key
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  for_each = aws_s3_bucket.tfstate

  bucket = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  for_each = aws_s3_bucket.tfstate

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  for_each = aws_s3_bucket.tfstate

  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "tfstate" {
  for_each = aws_s3_bucket.tfstate

  bucket = each.value.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Deniega cualquier trafico que no use TLS hacia el bucket de estado (Zero Trust:
# el transporte siempre cifrado).
resource "aws_s3_bucket_policy" "tfstate_tls_only" {
  for_each = aws_s3_bucket.tfstate

  bucket = each.value.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          each.value.arn,
          "${each.value.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
