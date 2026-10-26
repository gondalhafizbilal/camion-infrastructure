# AWS WAFv2 web ACL on the public ALB — COUNT MODE (non-blocking).
#
# Implements three asks against the shared ALB (module.backend_load_balancer):
#   - DDoS (L7):   AWSManagedRulesAmazonIpReputationList + AWSManagedRulesAnonymousIpList
#                  (AWS Shield Standard already covers L3/L4 automatically and for free)
#   - Scraping:    AWSManagedRulesCommonRuleSet now; optional paid Bot Control behind a toggle
#   - Rate limit:  per-IP rate_based rule
#
# Every rule runs in COUNT mode: managed groups -> override_action "count", the rate rule ->
# action "count", default_action "allow". Nothing is blocked — we observe counted metrics and
# sampled requests in dev, then flip selected rules to enforce later. Built with the Cloud
# Posse module (repo convention: prefer cloudposse/* registry modules), config driven by
# var.waf so dev/prod differ only via terraform.tfvars.

locals {
  # The web ACL name doubles as the CloudWatch "WebACL" dimension for the alarm below, so it
  # must be a stable string we control (not module.waf.id, which is the resource UUID).
  waf_acl_name = "${var.aws_profile}-alb"

  # Map var.waf.managed_rule_groups -> the module's managed_rule_group_statement_rules shape.
  # Bot Control is filtered out unless explicitly enabled, and its inspection level is nested
  # inside statement.managed_rule_group_configs (where the module expects it).
  waf_managed_rules = [
    for r in var.waf.managed_rule_groups : {
      name            = r.name
      priority        = r.priority
      override_action = r.override_action # "count" -> non-blocking
      statement = {
        name        = r.rule_group_name
        vendor_name = r.vendor_name
        managed_rule_group_configs = r.inspection_level == null ? null : [{
          aws_managed_rules_bot_control_rule_set = {
            inspection_level = r.inspection_level
          }
        }]
      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        sampled_requests_enabled   = true
        metric_name                = r.name
      }
    }
    if r.rule_group_name != "AWSManagedRulesBotControlRuleSet" || var.waf.bot_control_enabled
  ]
}

# WAF logging destination. The log group name MUST start with "aws-waf-logs-".
# AWS-managed encryption at rest: the shared KMS module exposes no CloudWatch-Logs CMK and a
# CMK would need a logs.<region>.amazonaws.com key policy — deferred (WAF telemetry is not
# secret). Retention bounded to keep cost down.
resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-${var.aws_profile}-alb"
  retention_in_days = var.waf.log_retention_days
  tags              = var.common_tags
}

module "waf" {
  source  = "cloudposse/waf/aws"
  version = "1.17.0"

  enabled = var.waf.enabled
  name    = local.waf_acl_name

  # REGIONAL is correct for an ALB in eu-north-1 (us-east-1 is only for CLOUDFRONT scope).
  scope          = "REGIONAL"
  default_action = "allow" # count mode: the ACL never blocks by default

  association_resource_arns = [module.backend_load_balancer.lb_arn]
  log_destination_configs   = [aws_cloudwatch_log_group.waf.arn]

  managed_rule_group_statement_rules = local.waf_managed_rules

  rate_based_statement_rules = [
    {
      name     = var.waf.rate_limit.name
      priority = var.waf.rate_limit.priority
      action   = var.waf.rate_limit.action # "count" -> non-blocking
      statement = {
        limit                 = var.waf.rate_limit.limit
        aggregate_key_type    = var.waf.rate_limit.aggregate_key_type
        evaluation_window_sec = var.waf.rate_limit.evaluation_window
      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        sampled_requests_enabled   = true
        metric_name                = var.waf.rate_limit.name
      }
    }
  ]

  visibility_config = {
    cloudwatch_metrics_enabled = true
    sampled_requests_enabled   = true
    metric_name                = local.waf_acl_name
  }

  tags = var.common_tags
}

# Early-warning alarm while non-blocking: fires when the rate rule COUNTS a lot of requests,
# i.e. someone is already over the limit and we'd be throttling if enforcing. Follows the
# ecs-alarms.tf pattern and publishes to the shared SNS topic.
# NOTE: the AWS/WAFV2 "WebACL" dimension is the ACL NAME, not the resource id.
resource "aws_cloudwatch_metric_alarm" "waf_rate_limit_counted" {
  count = var.waf.enabled ? 1 : 0

  alarm_name          = "${local.waf_acl_name}-waf-rate-limit-counted"
  alarm_description   = "WAF rate-based rule (count mode) is counting >1000 req/5min — would be throttling if enforcing."
  namespace           = "AWS/WAFV2"
  metric_name         = "CountedRequests"
  statistic           = "Sum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 1000
  period              = 300
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    WebACL = local.waf_acl_name
    Region = var.aws_region
    Rule   = var.waf.rate_limit.name
  }

  alarm_actions = [module.alarms_sns_topic.sns_topic.arn]
  ok_actions    = [module.alarms_sns_topic.sns_topic.arn]
  tags          = var.common_tags
}

output "waf_web_acl_arn" {
  description = "ARN of the ALB WAFv2 web ACL (count mode)."
  value       = module.waf.arn
}
