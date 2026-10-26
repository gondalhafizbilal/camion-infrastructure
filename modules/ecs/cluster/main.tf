data "aws_partition" "current" {}

## Cluster

locals {
  execute_command_configuration = {
    logging = "OVERRIDE"
    log_configuration = {
      cloud_watch_log_group_name = try(aws_cloudwatch_log_group.this[0].name, null)
    }
  }
}

resource "aws_ecs_cluster" "this" {
  count = var.create ? 1 : 0

  name = var.cluster_name

  dynamic "setting" {
    for_each = [var.cluster_settings]

    content {
      name  = setting.value.name
      value = setting.value.value
    }
  }

  tags = var.tags
}

## CloudWatch Log Group

resource "aws_cloudwatch_log_group" "this" {
  count = var.create && var.create_cloudwatch_log_group ? 1 : 0

  name              = "/aws/ecs/${var.cluster_name}"
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id

  tags = merge(var.tags, var.cloudwatch_log_group_tags)
}

## Cluster Capacity Providers

locals {
  default_capacity_providers = merge(
    { for k, v in var.fargate_capacity_providers : k => v if var.default_capacity_provider_use_fargate },
    { for k, v in var.autoscaling_capacity_providers : k => v if !var.default_capacity_provider_use_fargate }
  )
}

## Capacity Provider - Autoscaling Group(s)

resource "aws_ecs_capacity_provider" "this" {
  for_each = { for k, v in var.autoscaling_capacity_providers : k => v if var.create }

  name = try(each.value.name, each.key)

  auto_scaling_group_provider {
    auto_scaling_group_arn = each.value.auto_scaling_group_arn
    # When you use managed termination protection, you must also use managed scaling otherwise managed termination protection won't work
    managed_termination_protection = length(try([each.value.managed_scaling], [])) == 0 ? "DISABLED" : try(each.value.managed_termination_protection, null)

    dynamic "managed_scaling" {
      for_each = try([each.value.managed_scaling], [])

      content {
        # instance_warmup_period    = try(managed_scaling.value.instance_warmup_period, null)
        maximum_scaling_step_size = try(managed_scaling.value.maximum_scaling_step_size, null)
        minimum_scaling_step_size = try(managed_scaling.value.minimum_scaling_step_size, null)
        status                    = try(managed_scaling.value.status, null)
        target_capacity           = try(managed_scaling.value.target_capacity, null)
      }
    }
  }

  tags = merge(var.tags, try(each.value.tags, {}))
}

## Task Execution - IAM Role
#### https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html

locals {
  task_exec_iam_role_name = try(coalesce(var.task_exec_iam_role_name, var.cluster_name), "")

  create_task_exec_iam_role = var.create && var.create_task_exec_iam_role
  create_task_exec_policy   = local.create_task_exec_iam_role && var.create_task_exec_policy
}

data "aws_iam_policy_document" "task_exec_assume" {
  count = local.create_task_exec_iam_role ? 1 : 0

  statement {
    sid     = "ECSTaskExecutionAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.${data.aws_partition.current.dns_suffix}"]
    }
  }
}

resource "aws_iam_role" "task_exec" {
  count = local.create_task_exec_iam_role ? 1 : 0

  name        = var.task_exec_iam_role_use_name_prefix ? null : local.task_exec_iam_role_name
  name_prefix = var.task_exec_iam_role_use_name_prefix ? "${local.task_exec_iam_role_name}-" : null
  path        = var.task_exec_iam_role_path
  description = coalesce(var.task_exec_iam_role_description, "Task execution role for ${var.cluster_name}")

  assume_role_policy    = data.aws_iam_policy_document.task_exec_assume[0].json
  permissions_boundary  = var.task_exec_iam_role_permissions_boundary
  force_detach_policies = true

  tags = merge(var.tags, var.task_exec_iam_role_tags)
}

resource "aws_iam_role_policy_attachment" "task_exec_additional" {
  for_each = { for k, v in var.task_exec_iam_role_policies : k => v if local.create_task_exec_iam_role }

  role       = aws_iam_role.task_exec[0].name
  policy_arn = each.value
}

data "aws_iam_policy_document" "task_exec" {
  count = local.create_task_exec_policy ? 1 : 0

  # Pulled from AmazonECSTaskExecutionRolePolicy
  statement {
    sid = "Logs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }

  # Pulled from AmazonECSTaskExecutionRolePolicy
  statement {
    sid = "ECR"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = length(var.task_exec_ssm_param_arns) > 0 ? [1] : []

    content {
      sid       = "GetSSMParams"
      actions   = ["ssm:GetParameters"]
      resources = var.task_exec_ssm_param_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.task_exec_secret_arns) > 0 ? [1] : []

    content {
      sid       = "GetSecrets"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = var.task_exec_secret_arns
    }
  }

  dynamic "statement" {
    for_each = var.task_exec_iam_statements

    content {
      sid           = try(statement.value.sid, null)
      actions       = try(statement.value.actions, null)
      not_actions   = try(statement.value.not_actions, null)
      effect        = try(statement.value.effect, null)
      resources     = try(statement.value.resources, null)
      not_resources = try(statement.value.not_resources, null)

      dynamic "principals" {
        for_each = try(statement.value.principals, [])

        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "not_principals" {
        for_each = try(statement.value.not_principals, [])

        content {
          type        = not_principals.value.type
          identifiers = not_principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = try(statement.value.conditions, [])

        content {
          test     = condition.value.test
          values   = condition.value.values
          variable = condition.value.variable
        }
      }
    }
  }
}

resource "aws_iam_policy" "task_exec" {
  count = local.create_task_exec_policy ? 1 : 0

  name        = var.task_exec_iam_role_use_name_prefix ? null : local.task_exec_iam_role_name
  name_prefix = var.task_exec_iam_role_use_name_prefix ? "${local.task_exec_iam_role_name}-" : null
  description = coalesce(var.task_exec_iam_role_description, "Task execution role IAM policy")
  policy      = data.aws_iam_policy_document.task_exec[0].json

}

resource "aws_iam_role_policy_attachment" "task_exec" {
  count = local.create_task_exec_policy ? 1 : 0

  role       = aws_iam_role.task_exec[0].name
  policy_arn = aws_iam_policy.task_exec[0].arn
}
