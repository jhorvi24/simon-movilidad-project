###############################################################################
# Modulo: ecr
#
# Repositorio de imagenes de contenedor para la app.
#   - scan_on_push: escaneo de vulnerabilidades automatico (seguridad).
#   - image_tag_mutability: IMMUTABLE recomendado en prod (una tag no se
#     sobreescribe -> trazabilidad y Zero Trust en el supply chain).
#   - lifecycle policy: elimina imagenes viejas para controlar costos.
#   - cifrado en reposo.
###############################################################################

resource "aws_ecr_repository" "this" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = var.kms_key_arn != null ? "KMS" : "AES256"
    kms_key         = var.kms_key_arn
  }

  tags = {
    Name = var.repository_name
  }
}

# Mantiene solo las ultimas N imagenes etiquetadas y expira las untagged.
resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expira imagenes sin tag despues de 1 dia"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Mantiene solo las ultimas ${var.max_image_count} imagenes"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.max_image_count
        }
        action = { type = "expire" }
      }
    ]
  })
}

# Fuerza que todo pull/push use TLS (Zero Trust en transporte).
resource "aws_ecr_repository_policy" "tls_only" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "ecr:*"
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
