data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id          = var.cluster_name
  description                   = var.description
  engine                        = "redis"
  node_type                     = var.node_instance_type
  num_cache_clusters            = var.cache_node_count
  automatic_failover_enabled    = var.automatic_failover_enabled
  at_rest_encryption_enabled    = var.at_rest_encryption_enabled
  engine_version                = var.engine_version
  port                          = var.port
  apply_immediately             = false # Apply DB updates during next maintenance window
  maintenance_window            = var.maintenance_window
  snapshot_window               = var.snapshot_window
  subnet_group_name             = aws_elasticache_subnet_group.subnet_group.name
  security_group_ids            = var.security_group_ids
  kms_key_id                    = var.kms_key_id

  tags = merge(var.tags, {})
}

resource "aws_elasticache_subnet_group" "subnet_group" {
  name       = "${var.cluster_name}-subnet-group"
  subnet_ids = var.subnets
}

resource "aws_cloudwatch_log_group" "redis_logs" {
  name              = "${var.cluster_name}-logs-${data.aws_region.current.name}"
  retention_in_days = 90
  tags              = merge(var.tags, {})

}