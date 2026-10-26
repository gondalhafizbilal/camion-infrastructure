locals {
  product_translation_ssm_parameter_arns = {
    google_api_key                 = aws_ssm_parameter.pt_google_api_key.arn
    google_application_credentials = aws_ssm_parameter.pt_google_application_credentials.arn
    gcp_project_id                 = aws_ssm_parameter.pt_gcp_project_id.arn
    weaviate_url                   = aws_ssm_parameter.pt_weaviate_url.arn
    weaviate_api_key               = aws_ssm_parameter.pt_weaviate_api_key.arn
    wordpress_url                  = aws_ssm_parameter.pt_wordpress_url.arn
    jinaai_api_key                 = aws_ssm_parameter.pt_jinaai_api_key.arn
  }

  product_translation_runtime_environment = [
    { name = "NODE_ENV", value = var.common_tags.environment },
    { name = "PORT", value = tostring(var.product_translation_service.port) },
    { name = "REDIS_HOST", value = module.app_redis.endpoint },
    { name = "REDIS_PORT", value = tostring(var.app_redis.port) },
  ]

  product_translation_runtime_secrets = [
    { name = "GOOGLE_API_KEY", valueFrom = aws_ssm_parameter.pt_google_api_key.arn },
    { name = "GOOGLE_APPLICATION_CREDENTIALS", valueFrom = aws_ssm_parameter.pt_google_application_credentials.arn },
    { name = "GCP_PROJECT_ID", valueFrom = aws_ssm_parameter.pt_gcp_project_id.arn },
    { name = "WEAVIATE_URL", valueFrom = aws_ssm_parameter.pt_weaviate_url.arn },
    { name = "WEAVIATE_API_KEY", valueFrom = aws_ssm_parameter.pt_weaviate_api_key.arn },
    { name = "WORDPRESS_URL", valueFrom = aws_ssm_parameter.pt_wordpress_url.arn },
    { name = "JINAAI_API_KEY", valueFrom = aws_ssm_parameter.pt_jinaai_api_key.arn },
  ]
}

# ---------------------------------------------------------------------------
# SSM parameters for product-translation service
# ---------------------------------------------------------------------------

resource "aws_ssm_parameter" "pt_google_api_key" {
  name   = "/${var.common_tags.environment}/product-translation/GOOGLE_API_KEY"
  type   = "SecureString"
  value  = "CHANGE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "pt_google_application_credentials" {
  name   = "/${var.common_tags.environment}/product-translation/GOOGLE_APPLICATION_CREDENTIALS"
  type   = "SecureString"
  value  = "CHANGE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "pt_gcp_project_id" {
  name   = "/${var.common_tags.environment}/product-translation/GCP_PROJECT_ID"
  type   = "SecureString"
  value  = "CHANGE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "pt_weaviate_url" {
  name   = "/${var.common_tags.environment}/product-translation/WEAVIATE_URL"
  type   = "SecureString"
  value  = "CHANGE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "pt_weaviate_api_key" {
  name   = "/${var.common_tags.environment}/product-translation/WEAVIATE_API_KEY"
  type   = "SecureString"
  value  = "CHANGE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "pt_wordpress_url" {
  name   = "/${var.common_tags.environment}/product-translation/WORDPRESS_URL"
  type   = "SecureString"
  value  = "CHANGE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "pt_jinaai_api_key" {
  name   = "/${var.common_tags.environment}/product-translation/JINAAI_API_KEY"
  type   = "SecureString"
  value  = "CHANGE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

# ---------------------------------------------------------------------------
# ECR Repository
# ---------------------------------------------------------------------------
module "product_translation_ecr" {
  source               = "cloudposse/ecr/aws"
  name                 = "product-translation-repo"
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
module "ecs_cluster_product_translation" {
  source       = "../../../modules/ecs/cluster"
  cluster_name = "product-translation-cluster"
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
module "ecs_service_product_translation" {
  source                 = "../../../modules/ecs/service"
  enable_execute_command = true
  name                   = "product-translation-service"
  cluster_arn            = module.ecs_cluster_product_translation.arn

  cpu    = var.product_translation_service.cpu
  memory = var.product_translation_service.memory

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

  task_exec_ssm_param_arns = values(local.product_translation_ssm_parameter_arns)

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

  container_definitions = {
    product-translation = {
      cpu       = var.product_translation_service.cpu
      memory    = var.product_translation_service.memory
      essential = true
      image     = "${module.product_translation_ecr.repository_url}:${var.common_tags.environment}-latest"
      port_mappings = [
        {
          containerPort = var.product_translation_service.port
          hostPort      = var.product_translation_service.port
        }
      ]
      environment              = local.product_translation_runtime_environment
      secrets                  = local.product_translation_runtime_secrets
      readonly_root_filesystem = var.product_translation_service.readonly_root_filesystem
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.backend_load_balancer.target_group_arns[5]
      container_name   = "product-translation"
      container_port   = var.product_translation_service.port
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
      from_port                = var.product_translation_service.port
      to_port                  = var.product_translation_service.port
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
