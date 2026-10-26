output "arn" {
  description = "Cluster ARN"
  value       = aws_rds_cluster.this.arn
}

output "id" {
  description = "Cluster ID"
  value       = aws_rds_cluster.this.id
}

output "endpoint" {
  description = "Endpoint"
  value       = aws_rds_cluster.this.endpoint
}

output "hosted_zone_id" {
  description = "Canonical hosted zone ID of the load balancer.  Used for Route 53 entries."
  value       = aws_rds_cluster.this.hosted_zone_id
}

output "port" {
  description = "Port"
  value       = aws_rds_cluster.this.port
}

output "security_group_id" {
  description = "Security group allowed access to the cluster."
  value       = aws_security_group.default.id
}

output "replica_endpoints" {
  description = "List of replica instance endpoints"
  value       = aws_rds_cluster_instance.replicas[*].endpoint
}
