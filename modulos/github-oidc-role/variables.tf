variable "name_prefix" {
  description = "Prefijo para nombrar el rol (ej. simon-movilidad-dev)."
  type        = string
}

variable "project_name" {
  description = "Nombre base del proyecto, usado para acotar permisos IAM por prefijo."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN del OIDC provider de GitHub ya existente en la cuenta."
  type        = string
}

variable "github_repository" {
  description = "Repositorio en formato <org>/<repo> autorizado a asumir el rol."
  type        = string
}

variable "github_subject_claims" {
  description = "Claims 'sub' permitidos (sin el prefijo repo:<org>/<repo>:). Ej: ['environment:dev']."
  type        = list(string)
}

variable "state_bucket_arn" {
  description = "ARN del bucket S3 de estado remoto al que el pipeline debe acceder."
  type        = string
}
