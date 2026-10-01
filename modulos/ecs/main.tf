###############################################################################
# Modulo: ecs
#
# ECS Fargate: cluster + task definition + service + autoscaling.
#   - Las tareas corren en subnets PRIVADAS, sin IP publica (Zero Trust).
#   - El trafico entra solo por el ALB (SG encadenado en el modulo networking).
#   - Container Insights habilitado para observabilidad.
#   - Logs a CloudWatch.
#   - Application Auto Scaling por CPU y memoria (target tracking).
###############################################################################

resource "aws_ecs_cluster" "this" {
  name = "${var.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.name_prefix}-cluster"
  }
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.name_prefix}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_arn

  tags = {
    Name = "${var.name_prefix}-logs"
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.name_prefix}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      # Endurecimiento del contenedor (Zero Trust en runtime).
      readonlyRootFilesystem = var.readonly_root_filesystem

      # Con readonlyRootFilesystem=true TODO el rootfs es de solo lectura,
      # incluido /tmp. nginx necesita escribir el pid, los temporales y la
      # cache. Montamos volumenes efimeros (tmpfs) escribibles en esas rutas.
      mountPoints = var.readonly_root_filesystem ? [
        { sourceVolume = "tmp", containerPath = "/tmp", readOnly = false },
        { sourceVolume = "nginx-cache", containerPath = "/var/cache/nginx", readOnly = false },
        { sourceVolume = "nginx-run", containerPath = "/var/run", readOnly = false },
      ] : []

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  # Volumenes efimeros para las rutas escribibles que nginx necesita cuando el
  # root filesystem es de solo lectura. Solo se declaran si el endurecimiento
  # esta activo.
  dynamic "volume" {
    for_each = var.readonly_root_filesystem ? ["tmp", "nginx-cache", "nginx-run"] : []
    content {
      name = volume.value
    }
  }

  tags = {
    Name = "${var.name_prefix}-task"
  }
}

resource "aws_ecs_service" "this" {
  name            = "${var.name_prefix}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  # Despliegues sin downtime con rolling update + circuit breaker con rollback.
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.tasks_security_group_id]
    assign_public_ip = false # Zero Trust: tareas sin IP publica
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  # Permite al pipeline/ECS actualizar la imagen sin que Terraform revierta
  # el desired_count ajustado por autoscaling.
  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    Name = "${var.name_prefix}-service"
  }
}
