variable "name_prefix" {
  description = "Prefijo para nombrar recursos (ej. simon-movilidad-dev)."
  type        = string
}

variable "aws_region" {
  description = "Region de AWS (para la config de logs)."
  type        = string
}

# ---- Red --------------------------------------------------------------------
variable "private_subnet_ids" {
  description = "IDs de subnets privadas donde corren las tareas."
  type        = list(string)
}

variable "tasks_security_group_id" {
  description = "ID del security group de las tareas ECS."
  type        = string
}

# ---- Roles ------------------------------------------------------------------
variable "execution_role_arn" {
  description = "ARN del execution role de ECS."
  type        = string
}

variable "task_role_arn" {
  description = "ARN del task role de ECS."
  type        = string
}

# ---- Contenedor -------------------------------------------------------------
variable "container_name" {
  description = "Nombre del contenedor."
  type        = string
  default     = "app"
}

variable "container_image" {
  description = "Imagen del contenedor (ej. <ecr_url>:tag)."
  type        = string
}

variable "container_port" {
  description = "Puerto en el que escucha el contenedor."
  type        = number
  default     = 80
}

variable "readonly_root_filesystem" {
  description = "Monta el filesystem raiz del contenedor como solo lectura. true endurece el runtime."
  type        = bool
  default     = false
}

# ---- Tarea Fargate ----------------------------------------------------------
variable "task_cpu" {
  description = "CPU de la tarea (unidades Fargate: 256, 512, 1024...)."
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memoria de la tarea en MiB (512, 1024, 2048...)."
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Numero inicial de tareas del servicio."
  type        = number
  default     = 2
}

variable "health_check_grace_period_seconds" {
  description = "Segundos de gracia tras arrancar la tarea antes de evaluar el health check del ALB."
  type        = number
  default     = 120
}

# ---- ALB --------------------------------------------------------------------
variable "target_group_arn" {
  description = "ARN del target group del ALB al que se registran las tareas."
  type        = string
}

# ---- Logs -------------------------------------------------------------------
variable "log_retention_days" {
  description = "Dias de retencion de logs del contenedor."
  type        = number
  default     = 30
}

variable "log_kms_key_arn" {
  description = "ARN KMS para cifrar el log group. null = cifrado por defecto."
  type        = string
  default     = null
}

# ---- Autoscaling ------------------------------------------------------------
variable "autoscaling_min_capacity" {
  description = "Numero minimo de tareas."
  type        = number
  default     = 2
}

variable "autoscaling_max_capacity" {
  description = "Numero maximo de tareas."
  type        = number
  default     = 6
}

variable "cpu_target_value" {
  description = "Utilizacion de CPU objetivo (%) para el autoscaling."
  type        = number
  default     = 60
}

variable "memory_target_value" {
  description = "Utilizacion de memoria objetivo (%) para el autoscaling."
  type        = number
  default     = 70
}

variable "scale_in_cooldown" {
  description = "Segundos de espera antes de un scale-in."
  type        = number
  default     = 300
}

variable "scale_out_cooldown" {
  description = "Segundos de espera antes de un scale-out."
  type        = number
  default     = 60
}
