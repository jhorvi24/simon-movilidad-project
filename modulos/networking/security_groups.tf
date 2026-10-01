###############################################################################
# Security Groups (minimo privilegio / Zero Trust)
#
# Cadena de confianza:
#   Internet --(80)--> ALB SG --(container_port)--> Tareas ECS SG
#
# - El ALB acepta HTTP 80 desde internet (es el punto de entrada publico).
# - Las tareas SOLO aceptan trafico desde el SG del ALB, nunca desde 0.0.0.0/0.
#   Asi, aunque alguien conozca la IP privada de una tarea, no puede alcanzarla
#   sin pasar por el ALB.
###############################################################################

# ---- SG del ALB -------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "SG del ALB: entrada HTTP 80 desde internet"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.name_prefix}-alb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP entrante desde internet"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_tasks" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Salida hacia las tareas ECS en el puerto del contenedor"
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.tasks.id
}

# ---- SG de las tareas ECS ---------------------------------------------------
resource "aws_security_group" "tasks" {
  name        = "${var.name_prefix}-tasks-sg"
  description = "SG de las tareas ECS: entrada solo desde el ALB"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.name_prefix}-tasks-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "tasks_from_alb" {
  security_group_id            = aws_security_group.tasks.id
  description                  = "Trafico entrante solo desde el ALB"
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

# Salida a internet (via NAT) para pull de imagenes ECR, logs, etc.
resource "aws_vpc_security_group_egress_rule" "tasks_https_out" {
  security_group_id = aws_security_group.tasks.id
  description       = "HTTPS saliente (ECR, CloudWatch, etc.) via NAT"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}
