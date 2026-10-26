locals {
  chatbot_ssm_parameter_arns = {
    redis_uri      = aws_ssm_parameter.redis_uri.arn
    google_api_key = aws_ssm_parameter.chatbot_google_api_key.arn
    jinaai_api_key = aws_ssm_parameter.chatbot_jinaai_api_key.arn
    weaviate_url   = aws_ssm_parameter.chatbot_weaviate_url.arn
    weaviate_api_key = aws_ssm_parameter.chatbot_weaviate_api_key.arn
    # Twilio
    twilio_sms_enabled        = aws_ssm_parameter.twilio_sms_enabled.arn
    twilio_account_sid        = aws_ssm_parameter.twilio_account_sid.arn
    twilio_auth_token         = aws_ssm_parameter.twilio_auth_token.arn
    # SendGrid
    email_enabled                      = aws_ssm_parameter.email_enabled.arn
    email_from                         = aws_ssm_parameter.email_from.arn
    sendgrid_api_key                   = aws_ssm_parameter.sendgrid_api_key.arn
    sendgrid_template_otp              = aws_ssm_parameter.sendgrid_template_otp.arn
    sendgrid_template_order_confirmed  = aws_ssm_parameter.sendgrid_template_order_confirmed.arn
    sendgrid_template_order_shipped    = aws_ssm_parameter.sendgrid_template_order_shipped.arn
    sendgrid_template_order_processing = aws_ssm_parameter.sendgrid_template_order_processing.arn
    sendgrid_template_order_delivered  = aws_ssm_parameter.sendgrid_template_order_delivered.arn
    sendgrid_template_order_cancelled  = aws_ssm_parameter.sendgrid_template_order_cancelled.arn
  }

  chatbot_runtime_environment = [
    { name = "NODE_ENV", value = var.common_tags.environment },
    { name = "PORT", value = tostring(var.chatbot_service.port) },
    { name = "API_HOST", value = "https://${var.backend_service.host_header}" },
    { name = "NEXT_PUBLIC_CHATBOT_BASE_URL", value = "https://${var.chatbot_service.host_header}" },
    { name = "NEXT_PUBLIC_CHATBOT_PROXY_BASE", value = "/api/chatbot-proxy" },
    { name = "CHATBOT_UPSTREAM_BASE", value = "https://${var.chatbot_service.host_header}" },
  ]

  chatbot_runtime_secrets = [
    { name = "REDIS_URI", valueFrom = aws_ssm_parameter.redis_uri.arn },
    { name = "GOOGLE_API_KEY", valueFrom = aws_ssm_parameter.chatbot_google_api_key.arn },
    { name = "JINAAI_API_KEY", valueFrom = aws_ssm_parameter.chatbot_jinaai_api_key.arn },
    { name = "WEAVIATE_URL", valueFrom = aws_ssm_parameter.chatbot_weaviate_url.arn },
    { name = "WEAVIATE_API_KEY", valueFrom = aws_ssm_parameter.chatbot_weaviate_api_key.arn },
    # Twilio
    { name = "TWILIO_SMS_ENABLED",        valueFrom = aws_ssm_parameter.twilio_sms_enabled.arn },
    { name = "TWILIO_ACCOUNT_SID",        valueFrom = aws_ssm_parameter.twilio_account_sid.arn },
    { name = "TWILIO_AUTH_TOKEN",         valueFrom = aws_ssm_parameter.twilio_auth_token.arn },
    # SendGrid
    { name = "EMAIL_ENABLED",                      valueFrom = aws_ssm_parameter.email_enabled.arn },
    { name = "EMAIL_FROM",                         valueFrom = aws_ssm_parameter.email_from.arn },
    { name = "SENDGRID_API_KEY",                   valueFrom = aws_ssm_parameter.sendgrid_api_key.arn },
    { name = "SENDGRID_TEMPLATE_OTP",              valueFrom = aws_ssm_parameter.sendgrid_template_otp.arn },
    { name = "SENDGRID_TEMPLATE_ORDER_CONFIRMED",  valueFrom = aws_ssm_parameter.sendgrid_template_order_confirmed.arn },
    { name = "SENDGRID_TEMPLATE_ORDER_SHIPPED",    valueFrom = aws_ssm_parameter.sendgrid_template_order_shipped.arn },
    { name = "SENDGRID_TEMPLATE_ORDER_PROCESSING", valueFrom = aws_ssm_parameter.sendgrid_template_order_processing.arn },
    { name = "SENDGRID_TEMPLATE_ORDER_DELIVERED",  valueFrom = aws_ssm_parameter.sendgrid_template_order_delivered.arn },
    { name = "SENDGRID_TEMPLATE_ORDER_CANCELLED",  valueFrom = aws_ssm_parameter.sendgrid_template_order_cancelled.arn },
  ]
}

# ---------------------------------------------------------------------------
# SSM parameters for chatbot service
# ---------------------------------------------------------------------------

resource "aws_ssm_parameter" "chatbot_google_api_key" {
  name   = "/${var.common_tags.environment}/chatbot/GOOGLE_API_KEY"
  type   = "SecureString"
  value  = "AIzaSyAutON_x1Ir0zch-kAmugUt0XqRO66sORo"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "chatbot_jinaai_api_key" {
  name   = "/${var.common_tags.environment}/chatbot/JINAAI_API_KEY"
  type   = "SecureString"
  value  = "jina_40240ee05ebe41a18b9636e407797d3dPqmXGpjNPFynwmf-EtvtMLge_rNZ"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "chatbot_weaviate_url" {
  name   = "/${var.common_tags.environment}/chatbot/WEAVIATE_URL"
  type   = "SecureString"
  value  = "oxyka5ftdekbg0crmwfrw.c0.eu-central-1.aws.weaviate.cloud"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "chatbot_weaviate_api_key" {
  name   = "/${var.common_tags.environment}/chatbot/WEAVIATE_API_KEY"
  type   = "SecureString"
  value  = "YndRUnN2MllXQWxZMzkyQl9TdFYzaUhseUZhRmJwV3JYWk1GTmxKYWRvYkdnSWoyOWNEZXpYMDZNYytNPV92MjAw"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

# ---------------------------------------------------------------------------
# ECR Repository
# ---------------------------------------------------------------------------
module "chatbot_ecr" {
  source               = "cloudposse/ecr/aws"
  name                 = "chatbot-repo"
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
module "ecs_cluster_chatbot" {
  source       = "../../../modules/ecs/cluster"
  cluster_name = "chatbot-cluster"
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
module "ecs_service_chatbot" {
  source                 = "../../../modules/ecs/service"
  enable_execute_command = true
  name                   = "chatbot-service"
  cluster_arn            = module.ecs_cluster_chatbot.arn

  cpu    = var.chatbot_service.cpu
  memory = var.chatbot_service.memory

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

  task_exec_ssm_param_arns = values(local.chatbot_ssm_parameter_arns)

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
    chatbot = {
      cpu       = var.chatbot_service.cpu
      memory    = var.chatbot_service.memory
      essential = true
      image     = "${module.chatbot_ecr.repository_url}:${var.common_tags.environment}-latest"
      port_mappings = [
        {
          containerPort = var.chatbot_service.port
          hostPort      = var.chatbot_service.port
        }
      ]
      environment              = local.chatbot_runtime_environment
      secrets                  = local.chatbot_runtime_secrets
      readonly_root_filesystem = var.chatbot_service.readonly_root_filesystem
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.backend_load_balancer.target_group_arns[3]
      container_name   = "chatbot"
      container_port   = var.chatbot_service.port
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
      from_port                = var.chatbot_service.port
      to_port                  = var.chatbot_service.port
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
