variable "aws_region" {
  description = "Region de AWS donde se crean los buckets de estado."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto, usado como prefijo de recursos."
  type        = string
  default     = "simon-movilidad"
}

variable "github_repository" {
  description = "Repositorio <org>/<repo> autorizado por OIDC para los roles de deploy."
  type        = string
}
