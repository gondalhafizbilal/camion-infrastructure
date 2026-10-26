# ── GitHub Actions OIDC ─────────────────────────────────────────────────────

resource "aws_iam_openid_connect_provider" "github" {
  count = var.github_oidc_enabled ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = var.tags
}

resource "aws_iam_role" "github_actions" {
  count       = var.github_oidc_enabled ? 1 : 0
  name        = "github-actions-${var.github_branch}"
  description = "Assumed by GitHub Actions on ${var.github_org}/${var.github_repo}@${var.github_branch}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github[0].arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:environment:${var.github_branch}"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  for_each = var.github_oidc_enabled ? var.github_oidc_role_policies : {}

  role       = aws_iam_role.github_actions[0].name
  policy_arn = each.value
}

# ── EC2 SSM ──────────────────────────────────────────────────────────────────

resource "aws_iam_role" "ec2_ssm" {
  count       = var.role_ec2_ssm ? 1 : 0
  name        = "ec2-ssm"
  path        = "/"
  description = "Base EC2 role with SSM Core"

  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "cognito-idp.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
}
POLICY

  tags = var.tags
}

resource "aws_iam_instance_profile" "ec2_ssm" {
  count = var.role_ec2_ssm ? 1 : 0

  name = aws_iam_role.ec2_ssm[0].name
  role = aws_iam_role.ec2_ssm[0].name
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  count = var.role_ec2_ssm ? 1 : 0

  role       = aws_iam_role.ec2_ssm[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_role" "cloudformation" {
  count       = var.role_cloudformation ? 1 : 0
  name        = "cloudformation-service-role"
  path        = "/"
  description = "AWS cloudformation Service Role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": ["cloudformation.amazonaws.com", "codepipeline.amazonaws.com"]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

  tags = var.tags
}

resource "aws_iam_role_policy" "cloudformation" {
  count = var.role_cloudformation ? 1 : 0
  name  = "cloudformation-service"
  role  = aws_iam_role.cloudformation[0].id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Action": [
            "apigateway:*",
            "codedeploy:*",
            "lambda:*",
            "ec2:*",
            "events:CreateEventBus",
            "events:DeleteEventBus",
            "events:DescribeRule",
            "events:PutRule",
            "events:DeleteRule",
            "events:RemoveTargets",
            "events:PutTargets",
            "cloudformation:CreateChangeSet",
            "cloudformation:DescribeStacks",
            "iam:GetRole",
            "iam:CreateRole",
            "iam:DeleteRole",
            "iam:PutRolePolicy",
            "iam:AttachRolePolicy",
            "iam:DeleteRolePolicy",
            "iam:DetachRolePolicy",
            "iam:PassRole",
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetBucketVersioning",
            "ssm:GetParameters",
            "ssm:PutParameter"
        ],
        "Resource": "*",
        "Effect": "Allow"
    }
  ]
}
POLICY
}

resource "aws_iam_role" "api_gateway" {
  count       = var.role_api_gateway ? 1 : 0
  name        = "api-gateway-service-role"
  path        = "/"
  description = "AWS API Gateway Service Role"

  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "apigateway.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
}
POLICY

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "api_gateway" {
  count      = var.role_api_gateway ? 1 : 0
  role       = aws_iam_role.api_gateway[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}
