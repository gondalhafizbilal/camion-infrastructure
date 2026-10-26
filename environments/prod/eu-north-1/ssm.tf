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
#
# Third-party credential values are placeholders (REPLACE_ME). Fill them in
# via the AWS console after the first apply, then redeploy the ECS service
# (or wait for the next task replacement) to pick up the new values.
# ---------------------------------------------------------------------------

# Lifecycle on placeholder params: ignore value drift after manual updates.
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
# SkipCash payment gateway — REPLACE_ME (set in console post-deploy)
# ---------------------------------------------------------------------------
resource "aws_ssm_parameter" "skipcash_base_url" {
  name   = "/${var.common_tags.environment}/backend/SKIPCASH_BASE_URL"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "skipcash_client_id" {
  name   = "/${var.common_tags.environment}/backend/SKIPCASH_CLIENT_ID"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "skipcash_webhook_key" {
  name   = "/${var.common_tags.environment}/backend/SKIPCASH_WEBHOOK_KEY"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "skipcash_key_id" {
  name   = "/${var.common_tags.environment}/backend/SKIPCASH_KEY_ID"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "skipcash_key_secret" {
  name   = "/${var.common_tags.environment}/backend/SKIPCASH_KEY_SECRET"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

# ---------------------------------------------------------------------------
# GullTrans shipping — REPLACE_ME
# ---------------------------------------------------------------------------
resource "aws_ssm_parameter" "gulltrans_base_url" {
  name   = "/${var.common_tags.environment}/backend/GULLTRANS_BASE_URL"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "gulltrans_uuid" {
  name   = "/${var.common_tags.environment}/backend/GULLTRANS_UUID"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "gulltrans_authorization" {
  name   = "/${var.common_tags.environment}/backend/GULLTRANS_AUTHORIZATION"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "gulltrans_warehouse_id" {
  name   = "/${var.common_tags.environment}/backend/GULLTRANS_WAREHOUSE_ID"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "gulltrans_user_id" {
  name   = "/${var.common_tags.environment}/backend/GULLTRANS_USER_ID"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

# ---------------------------------------------------------------------------
# JOP WMS — REPLACE_ME
# ---------------------------------------------------------------------------
resource "aws_ssm_parameter" "jop_wms_base_url" {
  name   = "/${var.common_tags.environment}/backend/JOP_WMS_BASE_URL"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "jop_wms_api_key" {
  name   = "/${var.common_tags.environment}/backend/JOP_WMS_API_KEY"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "jop_wms_api_secret" {
  name   = "/${var.common_tags.environment}/backend/JOP_WMS_API_SECRET"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "jop_wms_provider_api_key" {
  name   = "/${var.common_tags.environment}/backend/JOP_WMS_PROVIDER_API_KEY"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "jop_wms_user_token" {
  name   = "/${var.common_tags.environment}/backend/JOP_WMS_USER_TOKEN"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "jop_wms_warehouse_code" {
  name   = "/${var.common_tags.environment}/backend/JOP_WMS_WAREHOUSE_CODE"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "jop_wms_logistics_channel" {
  name   = "/${var.common_tags.environment}/backend/JOP_WMS_LOGISTICS_CHANNEL"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

# ---------------------------------------------------------------------------
# App config (non-secret, sourced from terraform.tfvars)
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

# Magic OTP — left enabled with dev value per request; flip later.
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
# Twilio SMS — feature flag stays, all credentials REPLACE_ME
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
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "twilio_account_sid" {
  name   = "/${var.common_tags.environment}/backend/TWILIO_ACCOUNT_SID"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "twilio_auth_token" {
  name   = "/${var.common_tags.environment}/backend/TWILIO_AUTH_TOKEN"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

# ---------------------------------------------------------------------------
# SendGrid Email — feature flag + FROM address kept; API key + templates REPLACE_ME
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
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "sendgrid_template_otp" {
  name   = "/${var.common_tags.environment}/backend/SENDGRID_TEMPLATE_OTP"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "sendgrid_template_order_confirmed" {
  name   = "/${var.common_tags.environment}/backend/SENDGRID_TEMPLATE_ORDER_CONFIRMED"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "sendgrid_template_order_shipped" {
  name   = "/${var.common_tags.environment}/backend/SENDGRID_TEMPLATE_ORDER_SHIPPED"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "sendgrid_template_order_processing" {
  name   = "/${var.common_tags.environment}/backend/SENDGRID_TEMPLATE_ORDER_PROCESSING"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "sendgrid_template_order_delivered" {
  name   = "/${var.common_tags.environment}/backend/SENDGRID_TEMPLATE_ORDER_DELIVERED"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "sendgrid_template_order_cancelled" {
  name   = "/${var.common_tags.environment}/backend/SENDGRID_TEMPLATE_ORDER_CANCELLED"
  type   = "SecureString"
  value  = "REPLACE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
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
# Google OAuth — credentials CHANGE_ME (set in console post-deploy)
# ---------------------------------------------------------------------------
resource "aws_ssm_parameter" "google_client_id" {
  name   = "/${var.common_tags.environment}/backend/GOOGLE_CLIENT_ID"
  type   = "SecureString"
  value  = "CHANGE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "google_client_secret" {
  name   = "/${var.common_tags.environment}/backend/GOOGLE_CLIENT_SECRET"
  type   = "SecureString"
  value  = "CHANGE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "google_callback_url" {
  name   = "/${var.common_tags.environment}/backend/GOOGLE_CALLBACK_URL"
  type   = "SecureString"
  value  = "https://app.camiontrading.com/auth/google/callback"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "google_ios_client_id" {
  name   = "/${var.common_tags.environment}/backend/GOOGLE_IOS_CLIENT_ID"
  type   = "SecureString"
  value  = "CHANGE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "google_android_client_id" {
  name   = "/${var.common_tags.environment}/backend/GOOGLE_ANDROID_CLIENT_ID"
  type   = "SecureString"
  value  = "CHANGE_ME"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "frontend_redirect_url" {
  name   = "/${var.common_tags.environment}/backend/FRONTEND_REDIRECT_URL"
  type   = "SecureString"
  value  = "https://app.camion-app.com/en"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
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
  value  = "https://app.camiontrading.com/auth/facebook/callback"
  key_id = module.kms.ssm_key_arn
  tags   = var.common_tags
  lifecycle { ignore_changes = [value] }
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
  value  = "https://product-translation.camion-app.com"
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
