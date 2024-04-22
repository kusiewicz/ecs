resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["1B511ABEAD59C6CE207077C0BF0E0043B1382612"]
}

data "aws_iam_policy" "manage_ecr_containers" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

data "aws_iam_policy" "manage_ecs_tasks" {
  arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
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
      values   = ["repo:kusiewicz/koa:master"]
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

resource "aws_iam_role_policy_attachment" "manage_ecr_containers" {
  role       = aws_iam_role.github.name
  policy_arn = data.aws_iam_policy.manage_ecr_containers.arn
}

resource "aws_iam_role_policy_attachment" "manage_ecs_tasks" {
  role       = aws_iam_role.github.name
  policy_arn = data.aws_iam_policy.manage_ecs_tasks.arn
}
