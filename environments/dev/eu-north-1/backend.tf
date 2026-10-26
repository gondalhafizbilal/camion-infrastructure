locals {
  backend_ssm_parameter_arns = {
    db_host     = aws_ssm_parameter.db_host.arn
    db_port     = aws_ssm_parameter.db_port.arn
    db_username = aws_ssm_parameter.db_username.arn
    db_database = aws_ssm_parameter.db_database.arn
    redis_uri   = aws_ssm_parameter.redis_uri.arn
    # SkipCash
    skipcash_base_url    = aws_ssm_parameter.skipcash_base_url.arn
    skipcash_client_id   = aws_ssm_parameter.skipcash_client_id.arn
    skipcash_webhook_key = aws_ssm_parameter.skipcash_webhook_key.arn
    skipcash_key_id      = aws_ssm_parameter.skipcash_key_id.arn
    skipcash_key_secret  = aws_ssm_parameter.skipcash_key_secret.arn
    # GullTrans
    gulltrans_base_url      = aws_ssm_parameter.gulltrans_base_url.arn
    gulltrans_uuid          = aws_ssm_parameter.gulltrans_uuid.arn
    gulltrans_authorization = aws_ssm_parameter.gulltrans_authorization.arn
    gulltrans_warehouse_id  = aws_ssm_parameter.gulltrans_warehouse_id.arn
    gulltrans_user_id       = aws_ssm_parameter.gulltrans_user_id.arn
    # JOP WMS
    jop_wms_base_url          = aws_ssm_parameter.jop_wms_base_url.arn
    jop_wms_api_key           = aws_ssm_parameter.jop_wms_api_key.arn
    jop_wms_api_secret        = aws_ssm_parameter.jop_wms_api_secret.arn
    jop_wms_provider_api_key  = aws_ssm_parameter.jop_wms_provider_api_key.arn
    jop_wms_user_token        = aws_ssm_parameter.jop_wms_user_token.arn
    jop_wms_warehouse_code    = aws_ssm_parameter.jop_wms_warehouse_code.arn
    jop_wms_logistics_channel = aws_ssm_parameter.jop_wms_logistics_channel.arn
    # App config
    cors_origin            = aws_ssm_parameter.cors_origin.arn
    jwt_expires_in         = aws_ssm_parameter.jwt_expires_in.arn
    jwt_issuer             = aws_ssm_parameter.jwt_issuer.arn
    enable_magic_otp       = aws_ssm_parameter.enable_magic_otp.arn
    magic_otp              = aws_ssm_parameter.magic_otp.arn
    access_token_ttl       = aws_ssm_parameter.access_token_ttl.arn
    refresh_token_ttl_days = aws_ssm_parameter.refresh_token_ttl_days.arn
    # Twilio
    twilio_sms_enabled           = aws_ssm_parameter.twilio_sms_enabled.arn
    twilio_account_sid           = aws_ssm_parameter.twilio_account_sid.arn
    twilio_auth_token            = aws_ssm_parameter.twilio_auth_token.arn
    twilio_messaging_service_sid = aws_ssm_parameter.twilio_messaging_service_sid.arn
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
    # Mailchimp
    mailchimp_api_key     = aws_ssm_parameter.mailchimp_api_key.arn
    mailchimp_audience_id = aws_ssm_parameter.mailchimp_audience_id.arn
    # Google OAuth
    google_client_id         = aws_ssm_parameter.google_client_id.arn
    google_client_secret     = aws_ssm_parameter.google_client_secret.arn
    google_callback_url      = aws_ssm_parameter.google_callback_url.arn
    google_ios_client_id     = aws_ssm_parameter.google_ios_client_id.arn
    google_android_client_id = aws_ssm_parameter.google_android_client_id.arn
    frontend_redirect_url    = aws_ssm_parameter.frontend_redirect_url.arn
    # Facebook OAuth
    facebook_app_id       = aws_ssm_parameter.facebook_app_id.arn
    facebook_app_secret   = aws_ssm_parameter.facebook_app_secret.arn
    facebook_callback_url = aws_ssm_parameter.facebook_callback_url.arn
    # Apple Sign-In
    apple_audience    = aws_ssm_parameter.apple_audience.arn
    apple_issuer      = aws_ssm_parameter.apple_issuer.arn
    apple_team_id     = aws_ssm_parameter.apple_team_id.arn
    apple_key_id      = aws_ssm_parameter.apple_key_id.arn
    apple_private_key = aws_ssm_parameter.apple_private_key.arn
    # Product Translation
    product_translation_base_url = aws_ssm_parameter.product_translation_base_url.arn
    # Assets CDN
    assets_host = aws_ssm_parameter.assets_host.arn
  }

  # Only Terraform-derived outputs remain as plain environment variables.
  # Everything else is injected via SSM SecureString (see backend_runtime_secrets).
  backend_runtime_environment = [
    { name = "AWS_S3_BUCKET", value = module.assets_bucket.id },
    { name = "AWS_S3_REGION", value = var.aws_region },
    { name = "BULLMQ_HOST", value = module.bullmq_redis.endpoint },
    { name = "BULLMQ_PORT", value = tostring(var.bullmq_redis.port) },
    { name = "NODE_ENV", value = var.common_tags.environment },
    { name = "NODE_OPTIONS", value = "--max-old-space-size=5120" },
  ]

  backend_runtime_secrets = [
    { name = "DB_HOST", valueFrom = aws_ssm_parameter.db_host.arn },
    { name = "DB_PORT", valueFrom = aws_ssm_parameter.db_port.arn },
    { name = "DB_USERNAME", valueFrom = aws_ssm_parameter.db_username.arn },
    { name = "DB_DATABASE", valueFrom = aws_ssm_parameter.db_database.arn },
    { name = "REDIS_URI", valueFrom = aws_ssm_parameter.redis_uri.arn },
    { name = "DB_PASSWORD", valueFrom = "${data.aws_rds_cluster.app_postgres.master_user_secret[0].secret_arn}:password::" },
    # SkipCash
    { name = "SKIPCASH_BASE_URL", valueFrom = aws_ssm_parameter.skipcash_base_url.arn },
    { name = "SKIPCASH_CLIENT_ID", valueFrom = aws_ssm_parameter.skipcash_client_id.arn },
    { name = "SKIPCASH_WEBHOOK_KEY", valueFrom = aws_ssm_parameter.skipcash_webhook_key.arn },
    { name = "SKIPCASH_KEY_ID", valueFrom = aws_ssm_parameter.skipcash_key_id.arn },
    { name = "SKIPCASH_KEY_SECRET", valueFrom = aws_ssm_parameter.skipcash_key_secret.arn },
    # GullTrans
    { name = "GULLTRANS_BASE_URL", valueFrom = aws_ssm_parameter.gulltrans_base_url.arn },
    { name = "GULLTRANS_UUID", valueFrom = aws_ssm_parameter.gulltrans_uuid.arn },
    { name = "GULLTRANS_AUTHORIZATION", valueFrom = aws_ssm_parameter.gulltrans_authorization.arn },
    { name = "GULLTRANS_WAREHOUSE_ID", valueFrom = aws_ssm_parameter.gulltrans_warehouse_id.arn },
    { name = "GULLTRANS_USER_ID", valueFrom = aws_ssm_parameter.gulltrans_user_id.arn },
    # JOP WMS
    { name = "JOP_WMS_BASE_URL", valueFrom = aws_ssm_parameter.jop_wms_base_url.arn },
    { name = "JOP_WMS_API_KEY", valueFrom = aws_ssm_parameter.jop_wms_api_key.arn },
    { name = "JOP_WMS_API_SECRET", valueFrom = aws_ssm_parameter.jop_wms_api_secret.arn },
    { name = "JOP_WMS_PROVIDER_API_KEY", valueFrom = aws_ssm_parameter.jop_wms_provider_api_key.arn },
    { name = "JOP_WMS_USER_TOKEN", valueFrom = aws_ssm_parameter.jop_wms_user_token.arn },
    { name = "JOP_WMS_WAREHOUSE_CODE", valueFrom = aws_ssm_parameter.jop_wms_warehouse_code.arn },
    { name = "JOP_WMS_LOGISTICS_CHANNEL", valueFrom = aws_ssm_parameter.jop_wms_logistics_channel.arn },
    # App config
    { name = "CORS_ORIGIN", valueFrom = aws_ssm_parameter.cors_origin.arn },
    { name = "JWT_EXPIRES_IN", valueFrom = aws_ssm_parameter.jwt_expires_in.arn },
    { name = "JWT_ISSUER", valueFrom = aws_ssm_parameter.jwt_issuer.arn },
    { name = "ENABLE_MAGIC_OTP", valueFrom = aws_ssm_parameter.enable_magic_otp.arn },
    { name = "MAGIC_OTP", valueFrom = aws_ssm_parameter.magic_otp.arn },
    { name = "ACCESS_TOKEN_TTL", valueFrom = aws_ssm_parameter.access_token_ttl.arn },
    { name = "REFRESH_TOKEN_TTL_DAYS", valueFrom = aws_ssm_parameter.refresh_token_ttl_days.arn },
    # Twilio
    { name = "TWILIO_SMS_ENABLED", valueFrom = aws_ssm_parameter.twilio_sms_enabled.arn },
    { name = "TWILIO_ACCOUNT_SID", valueFrom = aws_ssm_parameter.twilio_account_sid.arn },
    { name = "TWILIO_AUTH_TOKEN", valueFrom = aws_ssm_parameter.twilio_auth_token.arn },
    { name = "TWILIO_MESSAGING_SERVICE_SID", valueFrom = aws_ssm_parameter.twilio_messaging_service_sid.arn },
    # SendGrid
    { name = "EMAIL_ENABLED", valueFrom = aws_ssm_parameter.email_enabled.arn },
    { name = "EMAIL_FROM", valueFrom = aws_ssm_parameter.email_from.arn },
    { name = "SENDGRID_API_KEY", valueFrom = aws_ssm_parameter.sendgrid_api_key.arn },
    { name = "SENDGRID_TEMPLATE_OTP", valueFrom = aws_ssm_parameter.sendgrid_template_otp.arn },
    { name = "SENDGRID_TEMPLATE_ORDER_CONFIRMED", valueFrom = aws_ssm_parameter.sendgrid_template_order_confirmed.arn },
    { name = "SENDGRID_TEMPLATE_ORDER_SHIPPED", valueFrom = aws_ssm_parameter.sendgrid_template_order_shipped.arn },
    { name = "SENDGRID_TEMPLATE_ORDER_PROCESSING", valueFrom = aws_ssm_parameter.sendgrid_template_order_processing.arn },
    { name = "SENDGRID_TEMPLATE_ORDER_DELIVERED", valueFrom = aws_ssm_parameter.sendgrid_template_order_delivered.arn },
    { name = "SENDGRID_TEMPLATE_ORDER_CANCELLED", valueFrom = aws_ssm_parameter.sendgrid_template_order_cancelled.arn },
    # Mailchimp
    { name = "MAILCHIMP_API_KEY", valueFrom = aws_ssm_parameter.mailchimp_api_key.arn },
    { name = "MAILCHIMP_AUDIENCE_ID", valueFrom = aws_ssm_parameter.mailchimp_audience_id.arn },
    # Google OAuth
    { name = "GOOGLE_CLIENT_ID", valueFrom = aws_ssm_parameter.google_client_id.arn },
    { name = "GOOGLE_CLIENT_SECRET", valueFrom = aws_ssm_parameter.google_client_secret.arn },
    { name = "GOOGLE_CALLBACK_URL", valueFrom = aws_ssm_parameter.google_callback_url.arn },
    { name = "GOOGLE_IOS_CLIENT_ID", valueFrom = aws_ssm_parameter.google_ios_client_id.arn },
    { name = "GOOGLE_ANDROID_CLIENT_ID", valueFrom = aws_ssm_parameter.google_android_client_id.arn },
    { name = "FRONTEND_REDIRECT_URL", valueFrom = aws_ssm_parameter.frontend_redirect_url.arn },
    # Facebook OAuth
    { name = "FACEBOOK_APP_ID", valueFrom = aws_ssm_parameter.facebook_app_id.arn },
    { name = "FACEBOOK_APP_SECRET", valueFrom = aws_ssm_parameter.facebook_app_secret.arn },
    { name = "FACEBOOK_CALLBACK_URL", valueFrom = aws_ssm_parameter.facebook_callback_url.arn },
    # Apple Sign-In
    { name = "APPLE_AUDIENCE", valueFrom = aws_ssm_parameter.apple_audience.arn },
    { name = "APPLE_ISSUER", valueFrom = aws_ssm_parameter.apple_issuer.arn },
    { name = "APPLE_TEAM_ID", valueFrom = aws_ssm_parameter.apple_team_id.arn },
    { name = "APPLE_KEY_ID", valueFrom = aws_ssm_parameter.apple_key_id.arn },
    { name = "APPLE_PRIVATE_KEY", valueFrom = aws_ssm_parameter.apple_private_key.arn },
    # Product Translation
    { name = "PRODUCT_TRANSLATION_BASE_URL", valueFrom = aws_ssm_parameter.product_translation_base_url.arn },
    # Assets CDN
    { name = "ASSETS_HOST", valueFrom = aws_ssm_parameter.assets_host.arn },
  ]
}

# Cluster
module "ecs_cluster_backend" {
  source       = "../../../modules/ecs/cluster"
  cluster_name = "backend-cluster"
  tags         = var.common_tags

  # Register both providers — FARGATE_SPOT is primary, FARGATE is the base fallback.
  # Because default_capacity_provider_use_fargate defaults to true, both providers
  # are registered as cluster-level defaults. This is expected behaviour.
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

# ECS Environment Variables
module "ecs_environment" {
  source      = "../../../modules/s3"
  bucket_name = var.ecs_environment_bucket_name
  kms_key_arn = module.kms.s3_key_arn
  versioning  = true
  mfa_delete  = false
  tags        = var.common_tags
}

# ECR Repo Creation
module "backend_ecr" {
  source               = "cloudposse/ecr/aws"
  name                 = "backend-repo"
  image_tag_mutability = "MUTABLE"
  encryption_configuration = {
    encryption_type = "KMS"
    kms_key         = module.kms.ecr_key_arn
  }
  scan_images_on_push = true
}

# Backend Service
module "ecs_service_backend" {
  source                 = "../../../modules/ecs/service"
  enable_execute_command = true
  name                   = "backend-service"
  cluster_arn            = module.ecs_cluster_backend.arn

  cpu    = var.backend_service.cpu
  memory = var.backend_service.memory

  # Spot-first: FARGATE_SPOT handles all tasks; FARGATE base=1 keeps one
  # on-demand task as a fallback if Spot capacity is unavailable.
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

  # Give the container 60s to pass the first ALB health check before ECS
  # considers it failed — Node.js cold starts with Redis/Postgres connections
  # can take longer than the default threshold window.
  health_check_grace_period_seconds = 60

  task_exec_ssm_param_arns = ["arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.common_tags.environment}/backend/*"]
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
    task_role_policy = aws_iam_policy.backend_task_role_policy.arn
  }

  container_definitions = {
    backend = {
      cpu       = var.backend_service.cpu
      memory    = var.backend_service.memory
      essential = true
      image     = "${module.backend_ecr.repository_url}:${var.common_tags.environment}-latest"
      port_mappings = [
        {
          containerPort = var.backend_service.port
          hostPort      = var.backend_service.port
        }
      ]
      environment = concat(
        local.backend_runtime_environment,
        []
      )
      secrets                  = local.backend_runtime_secrets
      readonly_root_filesystem = var.backend_service.readonly_root_filesystem
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.backend_load_balancer.target_group_arns[0]
      container_name   = "backend"
      container_port   = var.backend_service.port
    }
  }

  subnet_ids = tolist([
    module.vpc01.private_subnet_ids[var.availability_zones[0]],
    module.vpc01.private_subnet_ids[var.availability_zones[1]],
    module.vpc01.private_subnet_ids[var.availability_zones[2]],
  ])

  security_group_rules = {
    alb_ingress_8000 = {
      type                     = "ingress"
      from_port                = var.backend_service.port
      to_port                  = var.backend_service.port
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

resource "aws_iam_policy" "ecs_environment_bucket_access" {
  name        = "ecs-environment-bucket-access"
  description = "Allows ECS tasks to access the environment variables in the S3 bucket."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:GetObject"],
        Resource = ["arn:aws:s3:::${module.ecs_environment.id}",
        "arn:aws:s3:::${module.ecs_environment.id}/*"],
      },
      {
        Effect   = "Allow",
        Action   = ["s3:GetBucketLocation"],
        Resource = ["arn:aws:s3:::${module.ecs_environment.id}"],
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:GenerateDataKey"],
        Resource = [module.kms.s3_key_arn]
      },
      {
        Effect = "Allow"
        Action = ["ssm:DescribeSessions",
          "ssm:GetSession",
          "ssm:StartSession",
          "ssm:TerminateSession",
        "ssm:ResumeSession"],
        Resource = ["*"]
      }
    ],
  })
}

resource "aws_iam_policy" "backend_task_role_policy" {
  name        = "backend-task-role-policy"
  description = "Allows ECS tasks to access the environment variables in the S3 bucket."

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
        Sid    = "MwaaAccess"
        Effect = "Allow"
        Action = [
          "airflow:CreateWebLoginToken"
        ]
        Resource = "*"
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
