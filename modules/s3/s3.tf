data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_s3_bucket" "s3bucket" {
  bucket        = "${var.bucket_name}-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  acl           = var.acl
  force_destroy = var.force_destroy
  versioning {
    enabled = var.versioning
    mfa_delete = var.mfa_delete
  }
  dynamic "server_side_encryption_configuration" {
    for_each = var.kms_key_arn != null ? [1] : []
    content {
      rule {
        apply_server_side_encryption_by_default {
          kms_master_key_id = var.kms_key_arn
          sse_algorithm     = "aws:kms"
        }
      }
    }
  }
  dynamic "server_side_encryption_configuration" {
    for_each = var.kms_key_arn == null ? [1] : []
    content {
      rule {
        apply_server_side_encryption_by_default {
          sse_algorithm = "AES256"
        }
      }
    }
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_delete ? [1] : []

    content {
      id      = "delete-rule"
      enabled = true
      expiration {
        days = var.delete_days
      }
    }
  }
  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_retain ? [1] : []

    content {
      id      = "retain-rule"
      enabled = true
      transition {
        storage_class = "GLACIER"
        days          = var.retain_days
      }
      expiration {
        days = var.delete_days
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.bucket_name}-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  })
}

resource "aws_s3_bucket_cors_configuration" "default" {
  count = try(length(var.cors_configuration), 0) > 0 ? 1 : 0

  bucket = aws_s3_bucket.s3bucket.id

  dynamic "cors_rule" {
    for_each = var.cors_configuration

    content {
      # id              = cors_rule.value.id
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}
resource "aws_s3_bucket_public_access_block" "s3bucket_nopublic" {
  count                   = var.block_public_access ? 1 : 0
  bucket                  = aws_s3_bucket.s3bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "policy" {
  dynamic "statement" {
    for_each = var.access_logs_bucket ? ["elb"] : []
    content {
      sid    = "ElbAccessLogsAccount"
      effect = "Allow"
      actions = [
        "s3:PutObject"
      ]
      resources = [
        "${aws_s3_bucket.s3bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      ]
      principals {
        identifiers = ["arn:aws:iam::${var.elb_push_account_id[data.aws_region.current.name]}:root"]
        type        = "AWS"
      }
    }
  }
  dynamic "statement" {
    for_each = var.access_logs_bucket ? ["elb"] : []
    content {
      sid    = "ElbAccessLogsDelivery"
      effect = "Allow"
      actions = [
        "s3:PutObject"
      ]
      resources = [
        "${aws_s3_bucket.s3bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      ]
      principals {
        identifiers = ["delivery.logs.amazonaws.com"]
        type        = "Service"
      }
      condition {
        test     = "StringEquals"
        values   = ["bucket-owner-full-control"]
        variable = "s3:x-amz-acl"
      }
    }
  }
  dynamic "statement" {
    for_each = var.access_logs_bucket ? ["elb"] : []
    content {
      sid    = "ElbAccessLogsDeliveryAcl"
      effect = "Allow"
      actions = [
        "s3:GetBucketAcl"
      ]
      resources = [
        aws_s3_bucket.s3bucket.arn
      ]
      principals {
        identifiers = ["delivery.logs.amazonaws.com"]
        type        = "Service"
      }
    }
  }
}


resource "aws_s3_bucket_policy" "policy" {
  count  = var.access_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.s3bucket.id
  policy = data.aws_iam_policy_document.policy.json
}
