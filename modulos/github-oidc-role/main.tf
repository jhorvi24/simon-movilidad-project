###############################################################################
# Modulo: github-oidc-role
#
# Crea UN rol de IAM que GitHub Actions asume via OIDC para desplegar un
# ambiente. Este modulo contiene SOLO identidad (IAM): es barato, sin computo,
# y por eso vive en el stack bootstrap/ (no en los stacks de infra de app).
#
# Asi, crear la "llave" del pipeline NO obliga a aprovisionar VPC/ECS/ALB.
# El pipeline, una vez tiene el rol, crea toda la infra de la app el mismo.
###############################################################################

data "aws_caller_identity" "current" {}

locals {
  # Formato del sub de GitHub OIDC:
  #   repo:<org>/<repo>:environment:<environment>
  #   repo:<org>/<repo>:ref:refs/heads/<branch>
  #   repo:<org>/<repo>:pull_request
  #
  # Algunas organizaciones activan los claims con IDs inmutables, y el "sub"
  # llega como repo:<org>@<id>/<repo>@<id>:... En ese caso el nombre llano no
  # hace match. Para tolerarlo insertamos un comodin "*" tras el owner y tras el
  # repo, de modo que el patron acepte tanto el formato llano como el que trae
  # los @<id>. StringLike soporta "*".
  repo_parts    = split("/", var.github_repository)
  repo_wildcard = "${local.repo_parts[0]}*/${local.repo_parts[1]}*"

  github_subs = [for s in var.github_subject_claims : "repo:${local.repo_wildcard}:${s}"]
}

data "aws_iam_policy_document" "assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
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

resource "aws_iam_role" "this" {
  name                 = "${var.name_prefix}-gha-deploy"
  assume_role_policy   = data.aws_iam_policy_document.assume.json
  max_session_duration = 3600 # 1h: credenciales cortas (Zero Trust)

  tags = {
    Name = "${var.name_prefix}-gha-deploy"
  }
}

# Permisos del pipeline: acotados a los servicios del proyecto (no Admin).
data "aws_iam_policy_document" "permissions" {
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
      "ecr:DeleteRepository",
      "ecr:TagResource",
      "ecr:UntagResource",
      "ecr:ListTagsForResource",
      "ecr:SetRepositoryPolicy",
      "ecr:GetRepositoryPolicy",
      "ecr:PutLifecyclePolicy",
      "ecr:GetLifecyclePolicy",
      "ecr:PutImageScanningConfiguration",
    ]
    resources = ["*"]
  }

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

resource "aws_iam_role_policy" "this" {
  name   = "${var.name_prefix}-gha-deploy-policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.permissions.json
}
