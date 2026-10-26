output "elasticache_id" {
  description = "ID of elasticache cluster"
  value       = aws_elasticache_replication_group.redis.id
}

output "primary_endpoint" {
  description = "Primary Endpoint address to the cluster"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}