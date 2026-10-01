variable "aws_region" {
  description = "Region de AWS."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre base del proyecto."
  type        = string
  default     = "simon-movilidad"
}

variable "vpc_cidr" {
  description = "CIDR de la VPC de dev."
  type        = string
  default     = "10.10.0.0/16"
}

variable "container_port" {
  description = "Puerto del contenedor (nginx no-root escucha en 8080)."
  type        = number
  default     = 8080
}

variable "container_image" {
  description = "Imagen a desplegar. Vacio = placeholder publico. El pipeline pasa <ecr_url>:<tag>."
  type        = string
  default     = ""
}


