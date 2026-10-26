resource "aws_iam_user" "publisher" {
  count = var.user_ecs_github ? 1 : 0
  name = "github-ci"
  path = "/serviceaccounts/"

  tags = var.tags
}

resource "aws_iam_user_policy" "publisher" {
  count = var.user_ecs_github ? 1 : 0
  name = "github-actions-ci"
  user = aws_iam_user.publisher[count.index].name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "iam:PassRole",
        "iam:GetRole",
        "ecs:DescribeTaskDefinition",
        "ecs:DescribeServices",
        "ecs:UpdateService",
        "ecs:RegisterTaskDefinition",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:DescribeImages",
        "ecr:GetAuthorizationToken",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetLifecyclePolicy",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart",
        "ecr:*",
        "s3:GetObjectVersion",
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:ListBucket",
        "kms:GenerateDataKey"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "kms:Decrypt",
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_access_key" "publisher" {
  count = var.user_ecs_github ? 1 : 0
  user = aws_iam_user.publisher[count.index].name
}

resource "aws_ssm_parameter" "github_ci_user_access_key_id" {
  count = var.user_ecs_github ? 1 : 0
  name        = "/IAM/GITHUB-ACTIONS-ACCESS-KEY/ID"
  description = "AWS Access Key for the Github Actions IAM User."
  type        = "SecureString"
  key_id      = var.ssm_kms_key_id
  value       = aws_iam_access_key.publisher[count.index].id
  tags        = var.tags
}

resource "aws_ssm_parameter" "github_ci_user_secret_access_key" {
  count = var.user_ecs_github ? 1 : 0
  name        = "/IAM/GITHUB-ACTIONS-ACCESS-KEY/SECRET"
  description = "AWS Secret Access Key for the Github Actions IAM User."
  type        = "SecureString"
  key_id      = var.ssm_kms_key_id
  value       = aws_iam_access_key.publisher[count.index].secret
  tags        = var.tags
}