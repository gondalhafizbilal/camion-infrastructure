# ──────────────────────────────────────────────
# Alarms — SNS topic (cloudposse) + per-service ECS / ALB target-group alarms.
# Driven by var.alarms in terraform.tfvars: var.alarms.sns wires the topic and
# subscriptions; var.alarms.services maps each service (backend, frontend, …)
# to a list of alarm specs. Each spec becomes an aws_cloudwatch_metric_alarm
# with dimensions resolved from local.ecs_alarm_targets based on namespace
# (AWS/ECS → ClusterName+ServiceName, AWS/ApplicationELB → LoadBalancer+TargetGroup).
# ──────────────────────────────────────────────

module "alarms_sns_topic" {
  source  = "cloudposse/sns-topic/aws"
  version = "~> 0.21"

  name = var.alarms.sns.name

  subscribers = {
    for idx, sub in var.alarms.sns.subscriptions :
    "${sub.protocol}-${idx}" => {
      protocol               = sub.protocol
      endpoint               = sub.endpoint
      endpoint_auto_confirms = false
      raw_message_delivery   = false
    }
  }

  tags = var.common_tags
}

output "alarms_sns_topic_arn" {
  description = "ARN of the SNS topic alarms publish to."
  value       = module.alarms_sns_topic.sns_topic.arn
}

locals {
  # Maps a service key (used in var.alarms.services) to its ECS cluster name,
  # ECS service name, and ALB target-group ARN suffix. Add new services here
  # if a new ECS service is added to the platform.
  ecs_alarm_targets = {
    backend = {
      cluster_name            = module.ecs_cluster_backend.name
      service_name            = "backend-service"
      target_group_arn_suffix = module.backend_load_balancer.target_group_arn_suffixes[0]
    }
    frontend = {
      cluster_name            = module.ecs_cluster_frontend.name
      service_name            = "frontend-service"
      target_group_arn_suffix = module.backend_load_balancer.target_group_arn_suffixes[1]
    }
    dashboard = {
      cluster_name            = module.ecs_cluster_dashboard.name
      service_name            = "dashboard-service"
      target_group_arn_suffix = module.backend_load_balancer.target_group_arn_suffixes[2]
    }
    chatbot = {
      cluster_name            = module.ecs_cluster_chatbot.name
      service_name            = "chatbot-service"
      target_group_arn_suffix = module.backend_load_balancer.target_group_arn_suffixes[3]
    }
    image = {
      cluster_name            = module.ecs_cluster_image_service.name
      service_name            = "image-service"
      target_group_arn_suffix = module.backend_load_balancer.target_group_arn_suffixes[4]
    }
    product_translation = {
      cluster_name            = module.ecs_cluster_product_translation.name
      service_name            = "product-translation-service"
      target_group_arn_suffix = module.backend_load_balancer.target_group_arn_suffixes[5]
    }
  }

  # Flatten { service => [alarm, ...] } → { "<service>-<alarm>" => merged-spec }
  # for use in for_each. Services without a matching target are skipped.
  ecs_alarms_flat = merge([
    for svc, alarm_list in var.alarms.services :
    {
      for a in alarm_list :
      "${svc}-${a.name}" => merge(a, {
        service = svc
        target  = local.ecs_alarm_targets[svc]
      })
    }
    if contains(keys(local.ecs_alarm_targets), svc)
  ]...)
}

resource "aws_cloudwatch_metric_alarm" "service" {
  for_each = local.ecs_alarms_flat

  alarm_name          = "${var.common_tags.environment}-${each.value.service}-${each.value.name}"
  alarm_description   = each.value.description != "" ? each.value.description : "${each.value.namespace} ${each.value.metric_name} for ${each.value.service}"
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

  dimensions = (
    each.value.namespace == "AWS/ECS" ? {
      ClusterName = each.value.target.cluster_name
      ServiceName = each.value.target.service_name
      } : each.value.namespace == "AWS/ApplicationELB" ? {
      LoadBalancer = module.backend_load_balancer.lb_arn_suffix
      TargetGroup  = each.value.target.target_group_arn_suffix
    } : {}
  )

  alarm_actions = [module.alarms_sns_topic.sns_topic.arn]
  ok_actions    = [module.alarms_sns_topic.sns_topic.arn]

  tags = var.common_tags
}
