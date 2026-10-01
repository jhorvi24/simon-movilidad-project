###############################################################################
# OIDC federation: GitHub Actions -> AWS (Zero Trust en credenciales)
#
# En lugar de guardar AWS_ACCESS_KEY_ID / SECRET_ACCESS_KEY como secretos de
# larga duracion en GitHub, GitHub Actions presenta un token OIDC firmado y
# asume un rol de IAM para obtener credenciales TEMPORALES.
#
# La relacion de confianza (assume_role_policy) restringe:
#   - El emisor: token.actions.githubusercontent.com
#   - La audiencia: sts.amazonaws.com
#   - El "sub": solo el repo (y opcionalmente rama/environment) permitido.
#
# Asi, ni un token filtrado de otro repo puede asumir este rol.
###############################################################################

data "aws_caller_identity" "current" {}

# El OIDC provider de GitHub. Se crea una sola vez por cuenta; por eso es
# condicional: si ya existe, se pasa create_oidc_provider = false y se referencia
# el existente vía var.existing_oidc_provider_arn.
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # Thumbprints de GitHub. AWS ya no los valida estrictamente para OIDC de IAM,
  # pero el atributo sigue siendo requerido por el provider.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name = "${var.name_prefix}-github-oidc"
  }
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.existing_oidc_provider_arn

  # Construye los "sub" permitidos. Formato del sub de GitHub OIDC:
  #   repo:<org>/<repo>:ref:refs/heads/<branch>
  #   repo:<org>/<repo>:environment:<environment>
  #   repo:<org>/<repo>:pull_request
  github_subs = [for s in var.github_subject_claims : "repo:${var.github_repository}:${s}"]
}

data "aws_iam_policy_document" "github_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.github_subs
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name                 = "${var.name_prefix}-gha-deploy"
  assume_role_policy   = data.aws_iam_policy_document.github_assume.json
  max_session_duration = 3600 # 1h: credenciales cortas (Zero Trust)

  tags = {
    Name = "${var.name_prefix}-gha-deploy"
  }
}

# Permisos del pipeline: acotados a los servicios del proyecto (no Admin).
data "aws_iam_policy_document" "github_actions_permissions" {
  # Estado remoto en S3
  statement {
    sid    = "TerraformState"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      var.state_bucket_arn,
      "${var.state_bucket_arn}/*",
    ]
  }

  # ECR: push/pull de imagenes
  statement {
    sid    = "ECR"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:DescribeImages",
      "ecr:CreateRepository",
      "ecr:TagResource",
      "ecr:SetRepositoryPolicy",
      "ecr:GetRepositoryPolicy",
      "ecr:PutLifecyclePolicy",
      "ecr:GetLifecyclePolicy",
      "ecr:PutImageScanningConfiguration",
    ]
    resources = ["*"]
  }

  # Infra de la app: VPC, ECS, ALB, Auto Scaling, Logs
  statement {
    sid    = "AppInfra"
    effect = "Allow"
    actions = [
      "ec2:*",
      "ecs:*",
      "elasticloadbalancing:*",
      "application-autoscaling:*",
      "logs:*",
      "cloudwatch:*",
      "kms:*",
    ]
    resources = ["*"]
  }

  # IAM: solo para gestionar los roles/policies del propio proyecto (prefijo).
  statement {
    sid    = "ScopedIAM"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:UpdateRole",
      "iam:GetRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:PassRole",
      "iam:TagRole",
      "iam:ListInstanceProfilesForRole",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*",
    ]
  }
}

resource "aws_iam_role_policy" "github_actions" {
  name   = "${var.name_prefix}-gha-deploy-policy"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_permissions.json
}
