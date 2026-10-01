###############################################################################
# Modulo: alb
#
# Application Load Balancer publico (HTTP 80) que enruta el trafico a las tareas
# ECS Fargate. Como Fargate usa red awsvpc, el target group es de tipo "ip".
#
# Nota: solo HTTP porque no hay ACM/dominio. En produccion real se agregaria un
# listener HTTPS 443 con certificado ACM y redireccion 80->443. Ver variable
# enable_https_redirect_placeholder para dejarlo documentado.
###############################################################################

resource "aws_lb" "this" {
  name               = "${var.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  drop_invalid_header_fields = true # Zero Trust: descarta headers malformados
  enable_deletion_protection = var.enable_deletion_protection

  # Logs de acceso opcionales (recomendado en prod).
  dynamic "access_logs" {
    for_each = var.access_logs_bucket != null ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.name_prefix
      enabled = true
    }
  }

  tags = {
    Name = "${var.name_prefix}-alb"
  }
}

resource "aws_lb_target_group" "this" {
  name        = "${var.name_prefix}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # requerido para Fargate (awsvpc)

  # Draining mas corto que el default (300s) para reciclar targets rapido.
  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  # Al reemplazar el TG, crear el nuevo antes de destruir el viejo.
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.name_prefix}-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = {
    Name = "${var.name_prefix}-http-listener"
  }
}
