# ---------------------------------------------------------------------------
# Data source — retrieves the Aurora cluster to get the managed secret ARN.
# Requires module.app_postgres to exist in AWS before a plan/apply.
# ---------------------------------------------------------------------------
data "aws_rds_cluster" "app_postgres" {
  cluster_identifier = module.app_postgres.cluster_identifier
}

# ---------------------------------------------------------------------------
# SSM SecureString parameters — injected into ECS container at runtime.
# Path prefix: /${var.common_tags.environment}/backend/
# All encrypted with the customer-managed SSM KMS key.
# ---------------------------------------------------------------------------
resource "aws_ssm_parameter" "db_host" {
  name   = "/${var.common_tags.environment}/backend/DB_HOST"
  type   = "SecureString"
  value  = module.app_postgres.endpoint
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "db_port" {
  name   = "/${var.common_tags.environment}/backend/DB_PORT"
  type   = "SecureString"
  value  = tostring(data.aws_rds_cluster.app_postgres.port)
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "db_username" {
  name   = "/${var.common_tags.environment}/backend/DB_USERNAME"
  type   = "SecureString"
  value  = "masteruser"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "db_database" {
  name   = "/${var.common_tags.environment}/backend/DB_DATABASE"
  type   = "SecureString"
  value  = "app"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "redis_uri" {
  name   = "/${var.common_tags.environment}/backend/REDIS_URI"
  type   = "SecureString"
  value  = "rediss://${module.app_redis.endpoint}:${var.app_redis.port}"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

# ---------------------------------------------------------------------------
# SkipCash payment gateway
# ---------------------------------------------------------------------------
resource "aws_ssm_parameter" "skipcash_base_url" {
  name   = "/${var.common_tags.environment}/backend/SKIPCASH_BASE_URL"
  type   = "SecureString"
  value  = "https://skipcashtest.azurewebsites.net"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "skipcash_client_id" {
  name   = "/${var.common_tags.environment}/backend/SKIPCASH_CLIENT_ID"
  type   = "SecureString"
  value  = "6fab9fb3-a5d1-4222-9cf9-01d14b43bacd"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "skipcash_webhook_key" {
  name   = "/${var.common_tags.environment}/backend/SKIPCASH_WEBHOOK_KEY"
  type   = "SecureString"
  value  = "dd3d26c8-11b4-40b4-b27e-95c5ea829a8e"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "skipcash_key_id" {
  name   = "/${var.common_tags.environment}/backend/SKIPCASH_KEY_ID"
  type   = "SecureString"
  value  = "301d1b2d-d58e-48b7-a671-b1ac5a116ae2"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "skipcash_key_secret" {
  name   = "/${var.common_tags.environment}/backend/SKIPCASH_KEY_SECRET"
  type   = "SecureString"
  value  = "2tRYx+kBWXjXMpIRczDb2sUdh37hRz0jbcFXBdKU8dQbXp17FgDIfDBra7cubiI7xUpi2PczXewEbVhOHVRALillZb4Gl3Mm+JQuzdQZncmx7pbO9tPtm4Y8vxbK3sFcxfM43KblKDfLsYbdBpFD8JtbBY1PXEA3OlLk2waDIFvSnHmDNxyQsUAkWWNwrRIdSt1wy3jc6bjPj++N0O9gxS6uaKsmZTQlBJi48OUkY83a/Lxk6ar38sFzOBU5xPeFj2ct2Yf8yWK+MFm64Zc0Q2MC17chldc3ez0vdmD0AR8khg+NzZEkb2XuRFkmUPwYX9MYB7mTw4/PlZPzAZ5yOX4ArBckEYn4UO/68k6xyzMlnE8PA5gDro/lgEknfV25S9gl1TojCSOFSJu1Q5Gg06P15Rthr+L2svuixswTC+n8Rw6eh8CMzn/fZETVlPyB5ysYGP5zqeDfSrr5Ee0aafk1gvOp2GrWdQlkqkvxESKPL51QiyhbR2+np7frnTukypeKHO48LwT92MoNc4PRcw=="
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

# ---------------------------------------------------------------------------
# GullTrans shipping
# ---------------------------------------------------------------------------
resource "aws_ssm_parameter" "gulltrans_base_url" {
  name   = "/${var.common_tags.environment}/backend/GULLTRANS_BASE_URL"
  type   = "SecureString"
  value  = "https://api-jiyun-v3.haiouoms.com"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "gulltrans_uuid" {
  name   = "/${var.common_tags.environment}/backend/GULLTRANS_UUID"
  type   = "SecureString"
  value  = "e69784f4-3855-416d-bede-2783a1381efa"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "gulltrans_authorization" {
  name   = "/${var.common_tags.environment}/backend/GULLTRANS_AUTHORIZATION"
  type   = "SecureString"
  value  = "1852be40-86e4-4ba7-9283-96b4f73b072e"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "gulltrans_warehouse_id" {
  name   = "/${var.common_tags.environment}/backend/GULLTRANS_WAREHOUSE_ID"
  type   = "SecureString"
  value  = "1494"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "gulltrans_user_id" {
  name   = "/${var.common_tags.environment}/backend/GULLTRANS_USER_ID"
  type   = "SecureString"
  value  = "2512760"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

# ---------------------------------------------------------------------------
# JOP WMS (Overseas Warehouse Management System)
# ---------------------------------------------------------------------------
resource "aws_ssm_parameter" "jop_wms_base_url" {
  name   = "/${var.common_tags.environment}/backend/JOP_WMS_BASE_URL"
  type   = "SecureString"
  value  = "http://47.119.180.205:8899"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "jop_wms_api_key" {
  name   = "/${var.common_tags.environment}/backend/JOP_WMS_API_KEY"
  type   = "SecureString"
  value  = "3A1MG4MS53TBC"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "jop_wms_api_secret" {
  name   = "/${var.common_tags.environment}/backend/JOP_WMS_API_SECRET"
  type   = "SecureString"
  value  = "d5437ec69d6d46249828dd06d969dbe6"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "jop_wms_provider_api_key" {
  name   = "/${var.common_tags.environment}/backend/JOP_WMS_PROVIDER_API_KEY"
  type   = "SecureString"
  value  = "2NN727EDITJ9F"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "jop_wms_user_token" {
  name   = "/${var.common_tags.environment}/backend/JOP_WMS_USER_TOKEN"
  type   = "SecureString"
  value  = "b475f58585234453bc44587366995b25"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "jop_wms_warehouse_code" {
  name   = "/${var.common_tags.environment}/backend/JOP_WMS_WAREHOUSE_CODE"
  type   = "SecureString"
  value  = "JYLCNSZ01"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "jop_wms_logistics_channel" {
  name   = "/${var.common_tags.environment}/backend/JOP_WMS_LOGISTICS_CHANNEL"
  type   = "SecureString"
  value  = "SZ2_ZF"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

# ---------------------------------------------------------------------------
# App config
# ---------------------------------------------------------------------------
resource "aws_ssm_parameter" "cors_origin" {
  name   = "/${var.common_tags.environment}/backend/CORS_ORIGIN"
  type   = "SecureString"
  value  = var.backend_app_config.cors_origin
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "jwt_expires_in" {
  name   = "/${var.common_tags.environment}/backend/JWT_EXPIRES_IN"
  type   = "SecureString"
  value  = tostring(var.backend_app_config.jwt_expires_in)
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "jwt_issuer" {
  name   = "/${var.common_tags.environment}/backend/JWT_ISSUER"
  type   = "SecureString"
  value  = var.backend_app_config.jwt_issuer
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "enable_magic_otp" {
  name   = "/${var.common_tags.environment}/backend/ENABLE_MAGIC_OTP"
  type   = "SecureString"
  value  = "Yes"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "magic_otp" {
  name   = "/${var.common_tags.environment}/backend/MAGIC_OTP"
  type   = "SecureString"
  value  = "123456"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "access_token_ttl" {
  name   = "/${var.common_tags.environment}/backend/ACCESS_TOKEN_TTL"
  type   = "SecureString"
  value  = var.backend_app_config.access_token_ttl
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "refresh_token_ttl_days" {
  name   = "/${var.common_tags.environment}/backend/REFRESH_TOKEN_TTL_DAYS"
  type   = "SecureString"
  value  = var.backend_app_config.refresh_token_ttl_days
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

# ---------------------------------------------------------------------------
# Twilio SMS
# ---------------------------------------------------------------------------
resource "aws_ssm_parameter" "twilio_sms_enabled" {
  name   = "/${var.common_tags.environment}/backend/TWILIO_SMS_ENABLED"
  type   = "SecureString"
  value  = "true"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "twilio_messaging_service_sid" {
  name   = "/${var.common_tags.environment}/backend/TWILIO_MESSAGING_SERVICE_SID"
  type   = "SecureString"
  value  = "MGeae95a79eee74ea5723848e133a51bd7"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "twilio_account_sid" {
  name   = "/${var.common_tags.environment}/backend/TWILIO_ACCOUNT_SID"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "twilio_auth_token" {
  name   = "/${var.common_tags.environment}/backend/TWILIO_AUTH_TOKEN"
  type   = "SecureString"
  value  = "fff9f13762c1288a0f1f1b6b74d0df11"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

# ---------------------------------------------------------------------------
# SendGrid Email
# ---------------------------------------------------------------------------
resource "aws_ssm_parameter" "email_enabled" {
  name   = "/${var.common_tags.environment}/backend/EMAIL_ENABLED"
  type   = "SecureString"
  value  = "true"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "email_from" {
  name   = "/${var.common_tags.environment}/backend/EMAIL_FROM"
  type   = "SecureString"
  value  = "info@camiontrading.com"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "sendgrid_api_key" {
  name   = "/${var.common_tags.environment}/backend/SENDGRID_API_KEY"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "sendgrid_template_otp" {
  name   = "/${var.common_tags.environment}/backend/SENDGRID_TEMPLATE_OTP"
  type   = "SecureString"
  value  = "d-b8570889b53f4cd99d717b97fa521980"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "sendgrid_template_order_confirmed" {
  name   = "/${var.common_tags.environment}/backend/SENDGRID_TEMPLATE_ORDER_CONFIRMED"
  type   = "SecureString"
  value  = "d-103d0efb72e3480a84542a7d86af870e"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "sendgrid_template_order_shipped" {
  name   = "/${var.common_tags.environment}/backend/SENDGRID_TEMPLATE_ORDER_SHIPPED"
  type   = "SecureString"
  value  = "d-72d4f4999c554fb992c742e9da6c4f40"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "sendgrid_template_order_processing" {
  name   = "/${var.common_tags.environment}/backend/SENDGRID_TEMPLATE_ORDER_PROCESSING"
  type   = "SecureString"
  value  = "d-1539689c5f344dd2b94dd682118deba5"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "sendgrid_template_order_delivered" {
  name   = "/${var.common_tags.environment}/backend/SENDGRID_TEMPLATE_ORDER_DELIVERED"
  type   = "SecureString"
  value  = "d-f1bc5e08f2ec491e97ffbfcae53d5c7e"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "sendgrid_template_order_cancelled" {
  name   = "/${var.common_tags.environment}/backend/SENDGRID_TEMPLATE_ORDER_CANCELLED"
  type   = "SecureString"
  value  = "d-f3b992d82c164f85a7b491443dd6599a"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

# ---------------------------------------------------------------------------
# Mailchimp — values managed out-of-band via `aws ssm put-parameter`.
# ---------------------------------------------------------------------------
resource "aws_ssm_parameter" "mailchimp_api_key" {
  name   = "/${var.common_tags.environment}/backend/MAILCHIMP_API_KEY"
  type   = "SecureString"
  value  = "CHANGE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "mailchimp_audience_id" {
  name   = "/${var.common_tags.environment}/backend/MAILCHIMP_AUDIENCE_ID"
  type   = "SecureString"
  value  = "CHANGE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

# ---------------------------------------------------------------------------
# Google OAuth
# ---------------------------------------------------------------------------
resource "aws_ssm_parameter" "google_client_id" {
  name   = "/${var.common_tags.environment}/backend/GOOGLE_CLIENT_ID"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "google_client_secret" {
  name   = "/${var.common_tags.environment}/backend/GOOGLE_CLIENT_SECRET"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "google_callback_url" {
  name   = "/${var.common_tags.environment}/backend/GOOGLE_CALLBACK_URL"
  type   = "SecureString"
  value  = "https://app.dev.camiontrading.com/auth/google/callback"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "google_ios_client_id" {
  name   = "/${var.common_tags.environment}/backend/GOOGLE_IOS_CLIENT_ID"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "google_android_client_id" {
  name   = "/${var.common_tags.environment}/backend/GOOGLE_ANDROID_CLIENT_ID"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

resource "aws_ssm_parameter" "frontend_redirect_url" {
  name   = "/${var.common_tags.environment}/backend/FRONTEND_REDIRECT_URL"
  type   = "SecureString"
  value  = "https://app.dev.camiontrading.com/en"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

# ---------------------------------------------------------------------------
# Facebook OAuth — values managed out-of-band via `aws ssm put-parameter`.
# ---------------------------------------------------------------------------
resource "aws_ssm_parameter" "facebook_app_id" {
  name   = "/${var.common_tags.environment}/backend/FACEBOOK_APP_ID"
  type   = "SecureString"
  value  = "CHANGE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "facebook_app_secret" {
  name   = "/${var.common_tags.environment}/backend/FACEBOOK_APP_SECRET"
  type   = "SecureString"
  value  = "CHANGE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "facebook_callback_url" {
  name   = "/${var.common_tags.environment}/backend/FACEBOOK_CALLBACK_URL"
  type   = "SecureString"
  value  = "CHANGE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

# ---------------------------------------------------------------------------
# Apple Sign-In — values managed out-of-band via `aws ssm put-parameter`.
# ---------------------------------------------------------------------------
resource "aws_ssm_parameter" "apple_audience" {
  name   = "/${var.common_tags.environment}/backend/APPLE_AUDIENCE"
  type   = "SecureString"
  value  = "CHANGE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "apple_issuer" {
  name   = "/${var.common_tags.environment}/backend/APPLE_ISSUER"
  type   = "SecureString"
  value  = "CHANGE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "apple_team_id" {
  name   = "/${var.common_tags.environment}/backend/APPLE_TEAM_ID"
  type   = "SecureString"
  value  = "CHANGE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "apple_key_id" {
  name   = "/${var.common_tags.environment}/backend/APPLE_KEY_ID"
  type   = "SecureString"
  value  = "CHANGE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "apple_private_key" {
  name   = "/${var.common_tags.environment}/backend/APPLE_PRIVATE_KEY"
  type   = "SecureString"
  value  = "CHANGE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

# ---------------------------------------------------------------------------
# Product Translation
# ---------------------------------------------------------------------------
resource "aws_ssm_parameter" "product_translation_base_url" {
  name   = "/${var.common_tags.environment}/backend/PRODUCT_TRANSLATION_BASE_URL"
  type   = "SecureString"
  value  = "https://product-translation.dev.camiontrading.com"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}

# ---------------------------------------------------------------------------
# Static assets CDN
# ---------------------------------------------------------------------------
resource "aws_ssm_parameter" "assets_host" {
  name   = "/${var.common_tags.environment}/backend/ASSETS_HOST"
  type   = "SecureString"
  value  = "https://assets.${var.subdomain_name}"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
}
