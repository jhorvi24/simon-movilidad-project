variable "name_prefix" {
  description = "Prefijo para nombrar recursos (ej. simon-movilidad-dev)."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR de la VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Lista de AZs a usar. Si esta vacia, se toman las primeras 2 disponibles."
  type        = list(string)
  default     = []
}

variable "container_port" {
  description = "Puerto en el que escucha el contenedor de la app."
  type        = number
  default     = 80
}

variable "single_nat_gateway" {
  description = "Si es true, usa un solo NAT Gateway (mas barato, menos HA). Recomendado true en dev, false en prod."
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Dias de retencion de los VPC Flow Logs en CloudWatch."
  type        = number
  default     = 30
}

variable "log_kms_key_arn" {
  description = "ARN de la KMS key para cifrar el log group de flow logs. Si es null, usa cifrado por defecto de CloudWatch."
  type        = string
  default     = null
}
