variable "name_prefix" {
  description = "Prefijo para nombrar recursos (ej. simon-movilidad-dev)."
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC donde vive el ALB."
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs de las subnets publicas donde se despliega el ALB."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ID del security group del ALB."
  type        = string
}

variable "container_port" {
  description = "Puerto del contenedor hacia el que enruta el target group."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Ruta HTTP para el health check del target group."
  type        = string
  default     = "/"
}

variable "enable_deletion_protection" {
  description = "Protege el ALB contra borrado accidental. Recomendado true en prod."
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "Bucket S3 para logs de acceso del ALB. null = deshabilitado."
  type        = string
  default     = null
}
