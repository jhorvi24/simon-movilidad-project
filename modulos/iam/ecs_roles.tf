###############################################################################
# Roles de ECS
#
#   - execution_role: lo usa el AGENTE de ECS/Fargate para arrancar la tarea:
#     pull de imagen desde ECR y escritura de logs en CloudWatch.
#   - task_role: lo asume la APLICACION en runtime. Vacio por defecto (la app
#     de prueba no llama a ningun servicio de AWS). Minimo privilegio.
###############################################################################

data "aws_iam_policy_document" "ecs_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ---- Execution role ---------------------------------------------------------
resource "aws_iam_role" "ecs_execution" {
  name               = "${var.name_prefix}-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json

  tags = {
    Name = "${var.name_prefix}-ecs-execution"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_managed" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Permiso extra para escribir logs (el managed policy cubre ECR + logs base,
# pero explicitamos por si se usa un log group con KMS).
data "aws_iam_policy_document" "ecs_execution_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ecs_execution_logs" {
  name   = "${var.name_prefix}-ecs-execution-logs"
  role   = aws_iam_role.ecs_execution.id
  policy = data.aws_iam_policy_document.ecs_execution_logs.json
}

# ---- Task role (runtime de la app) ------------------------------------------
resource "aws_iam_role" "ecs_task" {
  name               = "${var.name_prefix}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json

  tags = {
    Name = "${var.name_prefix}-ecs-task"
  }
}

# Sin politicas por defecto: la app de prueba no necesita acceso a AWS.
# Se pueden agregar despues via var.task_role_policy_json si hiciera falta.
resource "aws_iam_role_policy" "ecs_task_extra" {
  count = var.task_role_policy_json != null ? 1 : 0

  name   = "${var.name_prefix}-ecs-task-extra"
  role   = aws_iam_role.ecs_task.id
  policy = var.task_role_policy_json
}
