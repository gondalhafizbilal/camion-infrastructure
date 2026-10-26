# Looks up the existing GitHub OIDC provider (created by module.iam) without re-creating it.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_policy" "github_actions_deploy" {
  name        = "github-actions-deploy-dev"
  description = "Allows GitHub Actions to push to ECR and deploy to ECS (dev)."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAuth"
        Effect = "Allow"
        Action = ["ecr:GetAuthorizationToken"]
        Resource = ["*"]
      },
      {
        Sid    = "ECRPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
        ]
        Resource = [module.backend_ecr.repository_arn]
      },
      {
        Sid    = "ECSdeploy"
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
        ]
        Resource = ["*"]
      },
    ]
  })
}

resource "aws_iam_policy" "github_actions_deploy_frontend" {
  name        = "github-actions-deploy-frontend-dev"
  description = "Allows GitHub Actions to push to ECR and deploy to ECS for frontend (dev)."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAuth"
        Effect = "Allow"
        Action = ["ecr:GetAuthorizationToken"]
        Resource = ["*"]
      },
      {
        Sid    = "ECRPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
        ]
        Resource = [module.frontend_ecr.repository_arn]
      },
      {
        Sid    = "ECSdeploy"
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
        ]
        Resource = ["*"]
      },
    ]
  })
}

resource "aws_iam_role" "github_actions_frontend" {
  name        = "github-actions-frontend-dev"
  description = "Assumed by GitHub Actions on CamionOfficial/camion-frontend-v2@dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:CamionOfficial/camion-frontend-v2:environment:dev"
        }
      }
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "github_actions_frontend" {
  role       = aws_iam_role.github_actions_frontend.name
  policy_arn = aws_iam_policy.github_actions_deploy_frontend.arn
}

resource "aws_iam_policy" "github_actions_deploy_dashboard" {
  name        = "github-actions-deploy-dashboard-dev"
  description = "Allows GitHub Actions to push to ECR and deploy to ECS for dashboard (dev)."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAuth"
        Effect = "Allow"
        Action = ["ecr:GetAuthorizationToken"]
        Resource = ["*"]
      },
      {
        Sid    = "ECRPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
        ]
        Resource = [module.dashboard_ecr.repository_arn]
      },
      {
        Sid    = "ECSdeploy"
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
        ]
        Resource = ["*"]
      },
    ]
  })
}

resource "aws_iam_role" "github_actions_dashboard" {
  name        = "github-actions-dashboard-dev"
  description = "Assumed by GitHub Actions on CamionOfficial/camion-dashboard-v2@dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:CamionOfficial/camion-dashboard-v2:environment:dev"
        }
      }
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "github_actions_dashboard" {
  role       = aws_iam_role.github_actions_dashboard.name
  policy_arn = aws_iam_policy.github_actions_deploy_dashboard.arn
}

resource "aws_iam_policy" "github_actions_deploy_chatbot" {
  name        = "github-actions-deploy-chatbot-dev"
  description = "Allows GitHub Actions to push to ECR and deploy to ECS for chatbot (dev)."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAuth"
        Effect = "Allow"
        Action = ["ecr:GetAuthorizationToken"]
        Resource = ["*"]
      },
      {
        Sid    = "ECRPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
        ]
        Resource = [module.chatbot_ecr.repository_arn]
      },
      {
        Sid    = "ECSdeploy"
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
        ]
        Resource = ["*"]
      },
    ]
  })
}

resource "aws_iam_role" "github_actions_chatbot" {
  name        = "github-actions-chatbot-dev"
  description = "Assumed by GitHub Actions on CamionOfficial/chatbot-service@dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:CamionOfficial/chatbot-service:environment:dev"
        }
      }
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "github_actions_chatbot" {
  role       = aws_iam_role.github_actions_chatbot.name
  policy_arn = aws_iam_policy.github_actions_deploy_chatbot.arn
}

resource "aws_iam_policy" "github_actions_deploy_image_service" {
  name        = "github-actions-deploy-image-service-dev"
  description = "Allows GitHub Actions to push to ECR and deploy to ECS for image-service (dev)."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAuth"
        Effect = "Allow"
        Action = ["ecr:GetAuthorizationToken"]
        Resource = ["*"]
      },
      {
        Sid    = "ECRPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
        ]
        Resource = [module.image_service_ecr.repository_arn]
      },
      {
        Sid    = "ECSdeploy"
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
        ]
        Resource = ["*"]
      },
    ]
  })
}

resource "aws_iam_role" "github_actions_image_service" {
  name        = "github-actions-image-service-dev"
  description = "Assumed by GitHub Actions on CamionOfficial/image-service@dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:CamionOfficial/image-service:environment:dev"
        }
      }
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "github_actions_image_service" {
  role       = aws_iam_role.github_actions_image_service.name
  policy_arn = aws_iam_policy.github_actions_deploy_image_service.arn
}

resource "aws_iam_policy" "github_actions_deploy_product_translation" {
  name        = "github-actions-deploy-product-translation-dev"
  description = "Allows GitHub Actions to push to ECR and deploy to ECS for product-translation (dev)."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAuth"
        Effect = "Allow"
        Action = ["ecr:GetAuthorizationToken"]
        Resource = ["*"]
      },
      {
        Sid    = "ECRPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
        ]
        Resource = [module.product_translation_ecr.repository_arn]
      },
      {
        Sid    = "ECSdeploy"
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
        ]
        Resource = ["*"]
      },
    ]
  })
}

resource "aws_iam_role" "github_actions_product_translation" {
  name        = "github-actions-product-translation-dev"
  description = "Assumed by GitHub Actions on CamionOfficial/product-translation-service@dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:CamionOfficial/product-translation-service:environment:dev"
        }
      }
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "github_actions_product_translation" {
  role       = aws_iam_role.github_actions_product_translation.name
  policy_arn = aws_iam_policy.github_actions_deploy_product_translation.arn
}

module "iam" {
  source         = "../../../modules/iam/general"
  role_ec2_ssm   = true
  ssm_kms_key_id = module.kms.ssm_key_id

  github_oidc_enabled = true
  github_org          = "CamionOfficial"
  github_repo         = "camion-backend-v2"
  github_branch       = "dev"
  github_oidc_role_policies = {
    deploy = aws_iam_policy.github_actions_deploy.arn
  }

  tags = var.common_tags
}


