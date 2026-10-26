# ──────────────────────────────────────────────────────────────────────────────
# Static Assets — S3 + CloudFront CDN
# Serves uploaded assets via assets.dev.camiontrading.com
# ──────────────────────────────────────────────────────────────────────────────

# CloudFront requires ACM certificates in us-east-1.
provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = var.aws_profile
}

# ── ACM Wildcard Certificate (us-east-1 for CloudFront) ─────────────────────
# Wildcard covers all *.dev.camiontrading.com CloudFront distributions.
# Domain is managed in Hostinger — add validation CNAMEs manually.

module "cloudfront_acm_certificate" {
  source = "cloudposse/acm-request-certificate/aws"

  providers = {
    aws = aws.us_east_1
  }

  domain_name                       = "*.${var.subdomain_name}"
  subject_alternative_names         = [var.subdomain_name]
  validation_method                 = "DNS"
  process_domain_validation_options = false
  wait_for_certificate_issued       = false
  ttl                               = "300"
}

output "cloudfront_acm_validation_records" {
  description = "CNAME records for CloudFront ACM certificate validation (add in Hostinger if Route53 delegation is not yet active)."
  value       = module.cloudfront_acm_certificate.domain_validation_options
}

# ── S3 Bucket (moved from backend.tf) ────────────────────────────────────────

module "assets_bucket" {
  source      = "../../../modules/s3"
  bucket_name = "${var.common_tags.environment}-assets"
  kms_key_arn = module.kms.s3_key_arn
  versioning  = false
  mfa_delete  = false
  tags        = var.common_tags
}

# ── KMS Key Policy — allow CloudFront to decrypt S3 objects ──────────────────
# The S3 KMS key only allows account root by default. CloudFront OAC needs
# kms:Decrypt and kms:GenerateDataKey to serve KMS-encrypted objects.

resource "aws_kms_key_policy" "s3_cloudfront" {
  key_id = module.kms.s3_key_id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "s3"
    Statement = [
      {
        Sid       = "EnableIAMUserPermissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowCloudFrontServicePrincipalSSEKMS"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.assets_cdn.cf_arn
          }
        }
      }
    ]
  })
}

# ── CloudFront CDN ───────────────────────────────────────────────────────────

module "assets_cdn" {
  source  = "cloudposse/cloudfront-s3-cdn/aws"
  version = "~> 2.0"

  # cloudposse null-label context
  namespace = var.common_tags.owner
  stage     = var.common_tags.environment
  name      = "assets"

  # Use our existing assets S3 bucket as the origin.
  origin_bucket                 = module.assets_bucket.id
  override_origin_bucket_policy = true

  # OAC (modern replacement for OAI)
  origin_access_type = "origin_access_control"

  # Keep the origin bucket fully private (all-true PAB) to match module.assets_bucket and
  # stop the two public-access-block resources ping-ponging. OAC policy is a conditional
  # service grant, not public, so block_public_policy=true is fine.
  block_origin_public_access_enabled = true

  # Custom domain
  aliases = ["assets.${var.subdomain_name}"]

  # ACM certificate — wildcard *.dev.camiontrading.com in us-east-1
  acm_certificate_arn = module.cloudfront_acm_certificate.arn

  # DNS — create Route53 alias record
  dns_alias_enabled = true
  parent_zone_id    = aws_route53_zone.primary.zone_id

  # Caching
  default_ttl = 86400 # 1 day
  min_ttl     = 0
  max_ttl     = 31536000 # 1 year
  compress    = true

  # Price class — North America + Europe (matches eu-north-1 origin)
  price_class = "PriceClass_100"

  # Viewer settings
  viewer_protocol_policy   = "redirect-to-https"
  minimum_protocol_version = "TLSv1.2_2021"
  allowed_methods          = ["GET", "HEAD", "OPTIONS"]
  cached_methods           = ["GET", "HEAD"]
  forward_cookies          = "none"
  forward_query_string     = false
  forward_header_values    = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"]

  # CORS for the S3 bucket (backend uploads, CDN reads)
  cors_allowed_origins = [var.backend_app_config.cors_origin]
  cors_allowed_methods = ["GET", "HEAD"]
  cors_allowed_headers = ["*"]

  # Disable the module's built-in logging bucket — we can add this later if needed.
  logging_enabled = false

  tags = var.common_tags
}

# ── Outputs ──────────────────────────────────────────────────────────────────

output "assets_cdn_domain" {
  description = "CloudFront domain name for static assets."
  value       = module.assets_cdn.cf_domain_name
}

output "assets_cdn_url" {
  description = "Custom domain URL for static assets."
  value       = "https://assets.${var.subdomain_name}"
}
