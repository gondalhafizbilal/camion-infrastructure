locals {
  frontend_ssm_parameter_arns = {
    # App config
    cors_origin            = aws_ssm_parameter.cors_origin.arn
    jwt_expires_in         = aws_ssm_parameter.jwt_expires_in.arn
    jwt_issuer             = aws_ssm_parameter.jwt_issuer.arn
    enable_magic_otp       = aws_ssm_parameter.enable_magic_otp.arn
    magic_otp              = aws_ssm_parameter.magic_otp.arn
    access_token_ttl       = aws_ssm_parameter.access_token_ttl.arn
    refresh_token_ttl_days = aws_ssm_parameter.refresh_token_ttl_days.arn
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

  frontend_runtime_environment = [
    { name = "NODE_ENV",     value = var.common_tags.environment },
    { name = "ASSETS_HOST",  value = "assets.${var.subdomain_name}" },
  ]

  frontend_runtime_secrets = [
    # App config
    { name = "CORS_ORIGIN",            valueFrom = aws_ssm_parameter.cors_origin.arn },
    { name = "JWT_EXPIRES_IN",         valueFrom = aws_ssm_parameter.jwt_expires_in.arn },
    { name = "JWT_ISSUER",             valueFrom = aws_ssm_parameter.jwt_issuer.arn },
    { name = "ENABLE_MAGIC_OTP",       valueFrom = aws_ssm_parameter.enable_magic_otp.arn },
    { name = "MAGIC_OTP",              valueFrom = aws_ssm_parameter.magic_otp.arn },
    { name = "ACCESS_TOKEN_TTL",       valueFrom = aws_ssm_parameter.access_token_ttl.arn },
    { name = "REFRESH_TOKEN_TTL_DAYS", valueFrom = aws_ssm_parameter.refresh_token_ttl_days.arn },
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

# ECR Repo
module "frontend_ecr" {
  source               = "cloudposse/ecr/aws"
  name                 = "frontend-repo"
  image_tag_mutability = "MUTABLE"
  encryption_configuration = {
    encryption_type = "KMS"
    kms_key         = module.kms.ecr_key_arn
  }
  scan_images_on_push = true
}

# Cluster
module "ecs_cluster_frontend" {
  source       = "../../../modules/ecs/cluster"
  cluster_name = "frontend-cluster"
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

# Frontend Service
module "ecs_service_frontend" {
  source                 = "../../../modules/ecs/service"
  enable_execute_command = true
  name                   = "frontend-service"
  cluster_arn            = module.ecs_cluster_frontend.arn

  cpu    = var.frontend_service.cpu
  memory = var.frontend_service.memory

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

  task_exec_ssm_param_arns = values(local.frontend_ssm_parameter_arns)

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

  container_definitions = {
    frontend = {
      cpu       = var.frontend_service.cpu
      memory    = var.frontend_service.memory
      essential = true
      image     = "${module.frontend_ecr.repository_url}:${var.common_tags.environment}-latest"
      port_mappings = [
        {
          containerPort = var.frontend_service.port
          hostPort      = var.frontend_service.port
        }
      ]
      environment              = local.frontend_runtime_environment
      secrets                  = local.frontend_runtime_secrets
      readonly_root_filesystem = var.frontend_service.readonly_root_filesystem
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.backend_load_balancer.target_group_arns[1]
      container_name   = "frontend"
      container_port   = var.frontend_service.port
    }
  }

  subnet_ids = tolist([
    module.vpc01.private_subnet_ids[var.availability_zones[0]],
    module.vpc01.private_subnet_ids[var.availability_zones[1]],
    module.vpc01.private_subnet_ids[var.availability_zones[2]],
  ])

  security_group_rules = {
    alb_ingress_3000 = {
      type                     = "ingress"
      from_port                = var.frontend_service.port
      to_port                  = var.frontend_service.port
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
