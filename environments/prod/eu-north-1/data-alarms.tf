# ──────────────────────────────────────────────
# Alarms — RDS (Aurora Serverless v2) + ElastiCache (Valkey).
# Driven by var.alarms.data in terraform.tfvars. Same alarm-spec shape as
# var.alarms.services in ecs-alarms.tf; each data key maps to a list of
# alarm specs. Dimensions are resolved from local.data_alarm_targets and
# only depend on the namespace declared on each spec.
# SNS topic is created in ecs-alarms.tf (module.alarms_sns_topic).
# ──────────────────────────────────────────────

locals {
  # CacheClusterId for single-node Valkey clusters follows the <name>-001 convention.
  data_alarm_targets = {
    app_postgres = {
      dimensions = {
        DBClusterIdentifier = module.app_postgres.cluster_identifier
      }
    }
    app_redis = {
      dimensions = {
        CacheClusterId = "${var.app_redis.cluster_name}-001"
      }
    }
    bullmq_redis = {
      dimensions = {
        CacheClusterId = "${var.bullmq_redis.cluster_name}-001"
      }
    }
  }

  data_alarms_flat = merge([
    for key, alarm_list in var.alarms.data :
    {
      for a in alarm_list :
      "${key}-${a.name}" => merge(a, {
        resource_key = key
        target       = local.data_alarm_targets[key]
      })
    }
    if contains(keys(local.data_alarm_targets), key)
  ]...)
}

resource "aws_cloudwatch_metric_alarm" "data" {
  for_each = local.data_alarms_flat

  alarm_name          = "${var.common_tags.environment}-${each.value.resource_key}-${each.value.name}"
  alarm_description   = each.value.description != "" ? each.value.description : "${each.value.namespace} ${each.value.metric_name} for ${each.value.resource_key}"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  datapoints_to_alarm = each.value.datapoints_to_alarm
  threshold           = each.value.threshold
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  extended_statistic  = each.value.extended_statistic
  treat_missing_data  = each.value.treat_missing_data

  dimensions = each.value.target.dimensions

  alarm_actions = [module.alarms_sns_topic.sns_topic.arn]
  ok_actions    = [module.alarms_sns_topic.sns_topic.arn]

  tags = var.common_tags
}
