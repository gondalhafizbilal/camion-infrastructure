locals {
  image_service_ssm_parameter_arns = {
    google_api_key = aws_ssm_parameter.image_service_google_api_key.arn
    api_host       = aws_ssm_parameter.image_service_api_host.arn
  }

  image_service_runtime_environment = [
    { name = "NODE_ENV", value = var.common_tags.environment },
    { name = "PORT", value = tostring(var.image_service.port) },
    { name = "AWS_S3_REGION", value = var.aws_region },
    { name = "AWS_S3_BUCKET", value = module.assets_bucket.id },
    { name = "DB_HOST", value = module.app_postgres.endpoint },
    { name = "DB_PORT", value = tostring(data.aws_rds_cluster.app_postgres.port) },
    { name = "DB_USERNAME", value = nonsensitive(module.app_postgres.master_username) },
    { name = "DB_DATABASE", value = "camion_image_service" },
  ]

  image_service_runtime_secrets = [
    { name = "GOOGLE_API_KEY", valueFrom = aws_ssm_parameter.image_service_google_api_key.arn },
    { name = "API_HOST", valueFrom = aws_ssm_parameter.image_service_api_host.arn },
    { name = "DB_PASSWORD", valueFrom = "${data.aws_rds_cluster.app_postgres.master_user_secret[0].secret_arn}:password::" },
  ]
}

# ---------------------------------------------------------------------------
# SSM parameters for image-service
# ---------------------------------------------------------------------------

resource "aws_ssm_parameter" "image_service_google_api_key" {
  name   = "/${var.common_tags.environment}/image-service/GOOGLE_API_KEY"
  type   = "SecureString"
  value  = "CHANGE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "image_service_api_host" {
  name   = "/${var.common_tags.environment}/image-service/API_HOST"
  type   = "SecureString"
  value  = "https://${var.backend_service.host_header}"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

# ---------------------------------------------------------------------------
# ECR Repository
# ---------------------------------------------------------------------------
module "image_service_ecr" {
  source               = "cloudposse/ecr/aws"
  name                 = "image-service-repo"
  image_tag_mutability = "MUTABLE"
  encryption_configuration = {
    encryption_type = "KMS"
    kms_key         = module.kms.ecr_key_arn
  }
  scan_images_on_push = true
}

# ---------------------------------------------------------------------------
# ECS Cluster
# ---------------------------------------------------------------------------
module "ecs_cluster_image_service" {
  source       = "../../../modules/ecs/cluster"
  cluster_name = "image-service-cluster"
  tags         = var.common_tags

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 0
        base   = 0
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 1
      }
    }
  }
}

# ---------------------------------------------------------------------------
# ECS Service
# ---------------------------------------------------------------------------
module "ecs_service_image_service" {
  source                 = "../../../modules/ecs/service"
  enable_execute_command = true
  name                   = "image-service"
  cluster_arn            = module.ecs_cluster_image_service.arn

  cpu    = var.image_service.cpu
  memory = var.image_service.memory

  capacity_provider_strategy = {
    spot = {
      capacity_provider = "FARGATE_SPOT"
      weight            = 1
      base              = 0
    }
    on_demand = {
      capacity_provider = "FARGATE"
      weight            = 0
      base              = 0
    }
  }

  health_check_grace_period_seconds = 60

  task_exec_ssm_param_arns = values(local.image_service_ssm_parameter_arns)
  task_exec_secret_arns    = ["arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:rds!cluster-*"]

  task_exec_iam_statements = {
    ecs_exec = {
      effect = "Allow"
      actions = [
        "ssm:DescribeSessions",
        "ssm:GetSession",
        "ssm:StartSession",
        "ssm:TerminateSession",
        "ssm:ResumeSession",
      ]
      resources = ["*"]
    }
  }

  task_exec_iam_role_policies = {
    env_bucket_access = aws_iam_policy.ecs_environment_bucket_access.arn
  }

  tasks_iam_role_policies = {
    task_role_policy = aws_iam_policy.image_service_task_role_policy.arn
  }

  container_definitions = {
    image-service = {
      cpu       = var.image_service.cpu
      memory    = var.image_service.memory
      essential = true
      image     = "${module.image_service_ecr.repository_url}:${var.common_tags.environment}-latest"
      port_mappings = [
        {
          containerPort = var.image_service.port
          hostPort      = var.image_service.port
        }
      ]
      environment              = local.image_service_runtime_environment
      secrets                  = local.image_service_runtime_secrets
      readonly_root_filesystem = var.image_service.readonly_root_filesystem
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.backend_load_balancer.target_group_arns[4]
      container_name   = "image-service"
      container_port   = var.image_service.port
    }
  }

  subnet_ids = tolist([
    module.vpc01.private_subnet_ids[var.availability_zones[0]],
    module.vpc01.private_subnet_ids[var.availability_zones[1]],
    module.vpc01.private_subnet_ids[var.availability_zones[2]],
  ])

  security_group_rules = {
    alb_ingress = {
      type                     = "ingress"
      from_port                = var.image_service.port
      to_port                  = var.image_service.port
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = aws_security_group.loadbalancer_sg.id
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = var.common_tags
}

# ---------------------------------------------------------------------------
# Task Role Policy — S3 access for image uploads
# ---------------------------------------------------------------------------
resource "aws_iam_policy" "image_service_task_role_policy" {
  name        = "image-service-task-role-policy"
  description = "Allows image-service ECS tasks to upload to the assets S3 bucket."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "KmsDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:GenerateDataKeyPairWithoutPlaintext",
          "kms:GenerateDataKeyPair",
          "kms:Encrypt",
          "kms:DescribeKey"
        ]
        Resource = module.kms.s3_key_arn
      },
      {
        Sid    = "AssetsBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetBucketLocation",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectTagging",
          "s3:GetObjectAcl",
          "s3:GetObjectTagging",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${module.assets_bucket.id}",
          "arn:aws:s3:::${module.assets_bucket.id}/*"
        ]
      }
    ]
  })
}
