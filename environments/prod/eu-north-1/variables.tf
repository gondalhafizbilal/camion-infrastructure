# Variables values defined in terraform.tfvars
variable "aws_region" {
  description = "Terraform deployment region"
  type        = string
}

variable "aws_profile" {
  description = "Local AWS profile used for TF authentication"
  type        = string
}

variable "common_tags" {
  description = "Common tags applied to resources"
  type        = map(any)
}

variable "availability_zones" {
  description = "Availability Zones to use in the operating region"
}

## Route53 Settings

variable "subdomain_name" {
  description = "Subdomain name for the region"
}

variable "additional_subdomain_name" {
  description = "Additional subdomain name for the region (alternate domain served by the ALB)."
  type        = string
}

## VPC Settings
variable "vpc01_name" {
  description = "VPC Name"
}

variable "vpc01_cidr" {
  description = "Full VPC Network CIDR"
}

## VPC AZ01 Settings
variable "vpc01_public_cidr_az01" {
  description = "CIDRs for public subnets in AZ01"
}

variable "vpc01_private_cidr_az01" {
  description = "CIDRs for private subnets in AZ01"
}

variable "vpc01_data_cidr_az01" {
  description = "CIDRs for data subnets in AZ01"
}

## VPC AZ02 Settings
variable "vpc01_public_cidr_az02" {
  description = "CIDRs for public subnets in AZ02"
}

variable "vpc01_private_cidr_az02" {
  description = "CIDRs for private subnets in AZ02"
}

variable "vpc01_data_cidr_az02" {
  description = "CIDRs for data subnets in AZ02"
}

## VPC AZ03 Settings
variable "vpc01_public_cidr_az03" {
  description = "CIDRs for public subnets in AZ03"
}

variable "vpc01_private_cidr_az03" {
  description = "CIDRs for private subnets in AZ03"
}

variable "vpc01_data_cidr_az03" {
  description = "CIDRs for data subnets in AZ03"
}

## Backend Application Load Balancer
variable "backend_load_balancer" {
  description = "ALl the configurations required to deploy ALB."
}

variable "r53_hosted_zone_id" {
  description = "Route53 hosted zone ID."
}

## Valkey (ElastiCache)
variable "app_redis" {
  description = "Configuration for the app Valkey (ElastiCache) cluster."
  type = object({
    cluster_name               = string
    description                = string
    at_rest_encryption_enabled = bool
    port                       = number
    node_instance_type         = string
    cache_node_count           = number
    automatic_failover_enabled = bool
    engine_version             = string
    maintenance_window         = string
  })
}

variable "bullmq_redis" {
  description = "Configuration for the BullMQ Valkey (ElastiCache) cluster."
  type = object({
    cluster_name               = string
    description                = string
    at_rest_encryption_enabled = bool
    port                       = number
    node_instance_type         = string
    cache_node_count           = number
    automatic_failover_enabled = bool
    engine_version             = string
    maintenance_window         = string
  })
}

variable "backend_service" {
  description = "Configuration for the backend ECS service."
  type = object({
    name                             = string
    port                             = number
    protocol                         = string
    cpu                              = number
    memory                           = number
    readonly_root_filesystem         = bool
    health_check_enabled             = bool
    health_check_path                = string
    health_check_healthy_threshold   = number
    health_check_unhealthy_threshold = number
    health_check_timeout             = number
    health_check_protocol            = string
    health_check_matcher             = string
    host_header                      = string
    alt_host_header                  = string
  })
}

variable "frontend_service" {
  description = "Configuration for the frontend ECS service."
  type = object({
    name                             = string
    port                             = number
    protocol                         = string
    cpu                              = number
    memory                           = number
    readonly_root_filesystem         = bool
    health_check_enabled             = bool
    health_check_path                = string
    health_check_healthy_threshold   = number
    health_check_unhealthy_threshold = number
    health_check_timeout             = number
    health_check_protocol            = string
    health_check_matcher             = string
    host_header                      = string
    alt_host_header                  = string
    apex_host_header                 = string
  })
}

variable "dashboard_service" {
  description = "Configuration for the dashboard ECS service."
  type = object({
    name                             = string
    port                             = number
    protocol                         = string
    cpu                              = number
    memory                           = number
    readonly_root_filesystem         = bool
    health_check_enabled             = bool
    health_check_path                = string
    health_check_healthy_threshold   = number
    health_check_unhealthy_threshold = number
    health_check_timeout             = number
    health_check_protocol            = string
    health_check_matcher             = string
    host_header                      = string
    alt_host_header                  = string
  })
}

variable "chatbot_service" {
  description = "Configuration for the chatbot ECS service."
  type = object({
    name                             = string
    port                             = number
    protocol                         = string
    cpu                              = number
    memory                           = number
    readonly_root_filesystem         = bool
    health_check_enabled             = bool
    health_check_path                = string
    health_check_healthy_threshold   = number
    health_check_unhealthy_threshold = number
    health_check_timeout             = number
    health_check_protocol            = string
    health_check_matcher             = string
    host_header                      = string
    alt_host_header                  = string
  })
}

variable "image_service" {
  description = "Configuration for the image-service ECS service."
  type = object({
    name                             = string
    port                             = number
    protocol                         = string
    cpu                              = number
    memory                           = number
    readonly_root_filesystem         = bool
    health_check_enabled             = bool
    health_check_path                = string
    health_check_healthy_threshold   = number
    health_check_unhealthy_threshold = number
    health_check_timeout             = number
    health_check_protocol            = string
    health_check_matcher             = string
    host_header                      = string
    alt_host_header                  = string
  })
}

variable "product_translation_service" {
  description = "Configuration for the product-translation ECS service."
  type = object({
    name                             = string
    port                             = number
    protocol                         = string
    cpu                              = number
    memory                           = number
    readonly_root_filesystem         = bool
    health_check_enabled             = bool
    health_check_path                = string
    health_check_healthy_threshold   = number
    health_check_unhealthy_threshold = number
    health_check_timeout             = number
    health_check_protocol            = string
    health_check_matcher             = string
    host_header                      = string
    alt_host_header                  = string
  })
}

variable "backend_app_config" {
  description = "Non-sensitive application configuration injected as ECS environment variables."
  type = object({
    cors_origin            = string
    jwt_expires_in         = number
    jwt_issuer             = string
    access_token_ttl       = string
    refresh_token_ttl_days = string
  })
}

## CloudWatch alarms + SNS
# One variable, sub-maps per service (backend, frontend, ...) and per data store
# (app_postgres, app_redis, bullmq_redis). Each entry is a list of alarm specs;
# every spec becomes an aws_cloudwatch_metric_alarm with dimensions resolved
# by ecs-alarms.tf / data-alarms.tf based on the namespace.
variable "alarms" {
  description = "CloudWatch alarms and SNS subscription config."
  type = object({
    sns = object({
      name = string
      subscriptions = list(object({
        protocol = string
        endpoint = string
      }))
    })

    services = optional(map(list(object({
      name                = string
      metric_name         = string
      namespace           = string
      statistic           = optional(string)
      extended_statistic  = optional(string)
      comparison_operator = string
      threshold           = number
      period              = number
      evaluation_periods  = number
      datapoints_to_alarm = optional(number)
      treat_missing_data  = optional(string, "notBreaching")
      description         = optional(string, "")
    }))), {})

    data = optional(map(list(object({
      name                = string
      metric_name         = string
      namespace           = string
      statistic           = optional(string)
      extended_statistic  = optional(string)
      comparison_operator = string
      threshold           = number
      period              = number
      evaluation_periods  = number
      datapoints_to_alarm = optional(number)
      treat_missing_data  = optional(string, "notBreaching")
      description         = optional(string, "")
    }))), {})
  })
}

variable "waf" {
  description = "WAFv2 count-mode config for the ALB (DDoS/scraping/rate-limit). All rules non-blocking. See docs/sdlc/specs/waf-dev-alb."
  type = object({
    enabled             = optional(bool, true)
    bot_control_enabled = optional(bool, false) # paid AWS Bot Control AMR; OFF by default
    log_retention_days  = optional(number, 30)

    rate_limit = optional(object({
      name               = optional(string, "rate-limit-ip")
      priority           = optional(number, 100)
      limit              = optional(number, 2000) # requests per window per IP
      evaluation_window  = optional(number, 300)  # seconds: 60|120|300|600
      aggregate_key_type = optional(string, "IP") # ALB is direct origin; XFF is spoofable
      action             = optional(string, "count")
    }), {})

    managed_rule_groups = optional(list(object({
      name             = string
      priority         = number
      rule_group_name  = string
      vendor_name      = optional(string, "AWS")
      override_action  = optional(string, "count") # MUST stay "count" for count mode
      inspection_level = optional(string)          # bot-control only -> nested statement cfg
      })), [
      { name = "ip-reputation", priority = 10, rule_group_name = "AWSManagedRulesAmazonIpReputationList" },
      { name = "anonymous-ip", priority = 20, rule_group_name = "AWSManagedRulesAnonymousIpList" },
      { name = "common-rule-set", priority = 30, rule_group_name = "AWSManagedRulesCommonRuleSet" },
      { name = "bot-control", priority = 40, rule_group_name = "AWSManagedRulesBotControlRuleSet", inspection_level = "COMMON" },
    ])
  })
  default = {}

  # Count-mode guardrail: the module maps any non-"count" override_action/action to an
  # ENFORCE action. Fail fast if a future edit tries to silently arm a rule.
  validation {
    condition = alltrue([
      for r in var.waf.managed_rule_groups : r.override_action == "count"
    ]) && var.waf.rate_limit.action == "count"
    error_message = "WAF rollout is count-mode only: every managed override_action and the rate action must be \"count\"."
  }
}
