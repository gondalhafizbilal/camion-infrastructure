variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for the dashboards"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ECS Services Configuration
variable "ecs_services" {
  description = "List of ECS services to monitor"
  type = list(object({
    name         = string
    cluster_name = string
  }))
  default = []
}

# RDS Instances Configuration
variable "rds_instances" {
  description = "List of RDS instances to monitor"
  type = list(object({
    identifier = string
  }))
  default = []
}

# Redis/ElastiCache Clusters Configuration
variable "redis_clusters" {
  description = "List of Redis/ElastiCache clusters to monitor"
  type = list(object({
    cluster_id = string
  }))
  default = []
}

# MWAA Environments Configuration
variable "mwaa_environments" {
  description = "List of MWAA environments to monitor"
  type = list(object({
    name = string
  }))
  default = []
}