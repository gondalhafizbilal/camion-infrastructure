data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  ebs_service_role_arn_provided = (
    var.service_role_autoscaling_arn != "" ||
    var.service_role_batch_arn != "" ||
    var.service_linked_role_spot_arn != "" ||
    var.service_role_spot_fleet_arn != ""
  )
}

data "aws_iam_policy_document" "ebs" {

  statement {
    sid = "Enable IAM User Permissions"

    actions   = ["kms:*"]
    effect    = "Allow"
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = compact([
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
        var.service_role_autoscaling_arn
      ])
    }
  }

  dynamic "statement" {
    for_each = local.ebs_service_role_arn_provided ? [1] : []
    content {
      sid = "Enable IAM Service Role Permissions"

      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncryptFrom",
        "kms:ReEncryptTo",
        "kms:GenerateDataKey",
        "kms:GenerateDataKeyWithoutPlaintext",
        "kms:DescribeKey",
      ]
      effect    = "Allow"
      resources = ["*"]

      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["ec2.${data.aws_region.current.name}.amazonaws.com"]
      }

      principals {
        type = "AWS"
        identifiers = compact([
          var.service_role_autoscaling_arn,
          var.service_role_batch_arn,
          var.service_linked_role_spot_arn,
          var.service_role_spot_fleet_arn
        ])
      }
    }

  }

  dynamic "statement" {
    for_each = local.ebs_service_role_arn_provided ? [1] : []
    content {

      actions = [
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant",
      ]
      effect    = "Allow"
      resources = ["*"]

      condition {
        test     = "Bool"
        variable = "kms:GrantIsForAWSResource"
        values   = ["true"]
      }

      principals {
        type = "AWS"
        identifiers = compact([
          var.service_role_autoscaling_arn,
          var.service_role_batch_arn,
          var.service_linked_role_spot_arn,
          var.service_role_spot_fleet_arn
        ])
      }
    }
  }
}

resource "aws_kms_key" "s3" {
  count = var.s3 ? 1 : 0

  description             = "s3"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.kms_key_rotation

  # Policy managed externally via aws_kms_key_policy to avoid conflicts
  # (e.g. CloudFront OAC needs kms:Decrypt added in static-assets.tf)

  tags = merge(var.tags, { "Name" = "s3" })
}

resource "aws_kms_alias" "s3" {
  count = var.s3 ? 1 : 0

  name          = "alias/s3"
  target_key_id = aws_kms_key.s3[count.index].key_id
}

resource "aws_kms_key" "efs" {
  count = var.efs ? 1 : 0

  description             = "efs"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.kms_key_rotation

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "efs",
    "Statement": [
        {
          "Sid": "Enable IAM User Permissions",
          "Effect": "Allow",
          "Principal": {
              "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          },
          "Action": "kms:*",
          "Resource": "*"
        }
    ]
}
POLICY
  tags   = merge(var.tags, { "Name" = "efs" })
}

resource "aws_kms_alias" "efs" {
  count = var.efs ? 1 : 0

  name          = "alias/efs"
  target_key_id = aws_kms_key.efs[count.index].key_id
}

resource "aws_kms_key" "ebs" {
  description             = "ebs"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.kms_key_rotation
  policy                  = data.aws_iam_policy_document.ebs.json

  tags = merge(var.tags, { "Name" = "ebs" })
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/ebs"
  target_key_id = aws_kms_key.ebs.key_id
}

resource "aws_kms_key" "rds" {
  count = var.rds ? 1 : 0

  description             = "rds"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.kms_key_rotation

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "rds",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        }
    ]
}
POLICY
  tags   = merge(var.tags, { "Name" = "rds" })
}

resource "aws_kms_alias" "rds" {
  count = var.rds ? 1 : 0

  name          = "alias/rds"
  target_key_id = aws_kms_key.rds[count.index].key_id
}

resource "aws_kms_key" "ssm" {
  count                   = var.ssm ? 1 : 0
  description             = "ssm"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.kms_key_rotation

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "ssm",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        }
    ]
}
POLICY
  tags   = merge(var.tags, { "Name" = "ssm" })
}

resource "aws_kms_alias" "ssm" {
  count         = var.ssm ? 1 : 0
  name          = "alias/ssm"
  target_key_id = aws_kms_key.ssm[count.index].key_id
}

resource "aws_kms_key" "fsx" {
  count                   = var.fsx ? 1 : 0
  description             = "fsx"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.kms_key_rotation

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "fsx",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        }
    ]
}
POLICY
  tags   = merge(var.tags, { "Name" = "fsx" })
}

resource "aws_kms_alias" "fsx" {
  count         = var.fsx ? 1 : 0
  name          = "alias/fsx"
  target_key_id = aws_kms_key.fsx[count.index].key_id
}

resource "aws_kms_key" "eks" {

  count                   = var.eks ? 1 : 0
  description             = "eks"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.kms_key_rotation

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "eks",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        }
    ]
}
POLICY
  tags   = merge(var.tags, { "Name" = "eks" })
}

resource "aws_kms_alias" "eks" {

  count         = var.eks ? 1 : 0
  name          = "alias/eks"
  target_key_id = aws_kms_key.eks[count.index].key_id
}

resource "aws_kms_key" "code_artifact" {

  count                   = var.code_artifact ? 1 : 0
  description             = "code_artifact"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.kms_key_rotation

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "eks",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        }
    ]
}
POLICY
  tags   = merge(var.tags, { "Name" = "code-artifact" })
}

resource "aws_kms_alias" "code_artifact" {

  count         = var.code_artifact ? 1 : 0
  name          = "alias/code-artifact"
  target_key_id = aws_kms_key.code_artifact[count.index].key_id
}

resource "aws_kms_key" "ecr" {
  count                   = var.ecr ? 1 : 0
  description             = "ecr"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.kms_key_rotation

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "ssm",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        }
    ]
}
POLICY
  tags   = merge(var.tags, { "Name" = "ecr" })
}

resource "aws_kms_alias" "ecr" {
  count         = var.ecr ? 1 : 0
  name          = "alias/ecr"
  target_key_id = aws_kms_key.ecr[count.index].key_id
}


resource "aws_kms_key" "sqs" {
  count                   = var.sqs ? 1 : 0
  description             = "sqs"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.kms_key_rotation

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "sqs",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        }
    ]
}
POLICY
  tags   = merge(var.tags, { "Name" = "sqs" })
}


resource "aws_kms_alias" "sqs" {
  count         = var.sqs ? 1 : 0
  name          = "alias/sqs"
  target_key_id = aws_kms_key.sqs[count.index].key_id
}

resource "aws_kms_key" "elasticache" {
  count = var.elasticache ? 1 : 0

  description             = "elasticache"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.kms_key_rotation

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "elasticache",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        }
    ]
}
POLICY
  tags   = merge(var.tags, { "Name" = "elasticache" })
}

resource "aws_kms_alias" "elasticache" {
  count = var.elasticache ? 1 : 0

  name          = "alias/elasticache"
  target_key_id = aws_kms_key.elasticache[count.index].key_id
}