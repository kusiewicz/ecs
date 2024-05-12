resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["1B511ABEAD59C6CE207077C0BF0E0043B1382612"]
}

data "aws_iam_policy_document" "manage_ecr_container" {
  statement {
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]

    resources = [var.ecr_arn]
  }
}

resource "aws_iam_policy" "manage_ecr_container" {
  name   = "manage_ecr_container"
  policy = data.aws_iam_policy_document.manage_ecr_container.json
}

data "aws_iam_policy_document" "manage_ecs_task" {
  statement {
    actions = [
      "ecs:StartTask",
      "ecs:StopTask",
      "ecs:DescribeTasks",
      "ecs:ListTasks"
    ]

    resources = [var.ecs_task_arn]
  }
}

data "aws_iam_policy_document" "ecr_auth" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr_auth" {
  name   = "ecr_auth"
  policy = data.aws_iam_policy_document.ecr_auth.json
}

resource "aws_iam_policy" "manage_ecs_task" {
  name   = "manage_ecs_task"
  policy = data.aws_iam_policy_document.manage_ecs_task.json
}

data "aws_iam_policy_document" "github_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:kusiewicz/koa:ref:refs/heads/master"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "github" {
  name               = "GithubRole"
  assume_role_policy = data.aws_iam_policy_document.github_trust.json
}

resource "aws_iam_role_policy_attachment" "ecr_auth" {
  role       = aws_iam_role.github.name
  policy_arn = aws_iam_policy.ecr_auth.arn
}

resource "aws_iam_role_policy_attachment" "manage_ecr_containers" {
  role       = aws_iam_role.github.name
  policy_arn = aws_iam_policy.manage_ecr_container.arn
}

resource "aws_iam_role_policy_attachment" "manage_ecs_tasks" {
  role       = aws_iam_role.github.name
  policy_arn = aws_iam_policy.manage_ecs_task.arn
}
