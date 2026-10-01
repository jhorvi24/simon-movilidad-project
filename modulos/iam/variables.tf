variable "name_prefix" {
  description = "Prefijo para nombrar recursos (ej. simon-movilidad-dev)."
  type        = string
}

# ---- ECS task role ----------------------------------------------------------
variable "task_role_policy_json" {
  description = "Politica IAM (JSON) opcional para el task role de la app. null = sin permisos extra."
  type        = string
  default     = null
}
