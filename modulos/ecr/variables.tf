variable "repository_name" {
  description = "Nombre del repositorio ECR."
  type        = string
}

variable "image_tag_mutability" {
  description = "MUTABLE o IMMUTABLE. IMMUTABLE recomendado en prod."
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Debe ser MUTABLE o IMMUTABLE."
  }
}

variable "max_image_count" {
  description = "Numero maximo de imagenes a retener."
  type        = number
  default     = 10
}

variable "force_delete" {
  description = "Permite borrar el repo aunque tenga imagenes. true util en dev."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "ARN de KMS para cifrar las imagenes. null = AES256 gestionado por AWS."
  type        = string
  default     = null
}
