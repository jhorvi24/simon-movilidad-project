variable "name_prefix" {
  description = "Prefijo para nombrar recursos (ej. simon-movilidad-dev)."
  type        = string
}

variable "project_name" {
  description = "Nombre base del proyecto, usado para acotar permisos IAM por prefijo."
  type        = string
}

# ---- OIDC / GitHub ----------------------------------------------------------
variable "create_oidc_provider" {
  description = "Si es true, crea el OIDC provider de GitHub. Solo uno por cuenta AWS (crear en dev, reutilizar en prod)."
  type        = bool
  default     = true
}

variable "existing_oidc_provider_arn" {
  description = "ARN de un OIDC provider de GitHub ya existente. Requerido si create_oidc_provider = false."
  type        = string
  default     = null
}

variable "github_repository" {
  description = "Repositorio en formato <org>/<repo> autorizado a asumir el rol de deploy."
  type        = string
}

variable "github_subject_claims" {
  description = "Claims 'sub' permitidos (sin el prefijo repo:<org>/<repo>:). Ej: ['environment:dev', 'ref:refs/heads/main']."
  type        = list(string)
}

variable "state_bucket_arn" {
  description = "ARN del bucket S3 de estado remoto al que el pipeline debe acceder."
  type        = string
}

# ---- ECS task role ----------------------------------------------------------
variable "task_role_policy_json" {
  description = "Politica IAM (JSON) opcional para el task role de la app. null = sin permisos extra."
  type        = string
  default     = null
}
