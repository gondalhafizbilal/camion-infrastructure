output "ecs_dashboard_name" {
  description = "Name of the ECS Fargate dashboard"
  value       = aws_cloudwatch_dashboard.ecs_fargate.dashboard_name
}

output "ecs_dashboard_url" {
  description = "URL of the ECS Fargate dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.ecs_fargate.dashboard_name}"
}

output "database_dashboard_name" {
  description = "Name of the database dashboard"
  value       = aws_cloudwatch_dashboard.database.dashboard_name
}

output "database_dashboard_url" {
  description = "URL of the database dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.database.dashboard_name}"
}

output "mwaa_dashboard_name" {
  description = "Name of the MWAA dashboard"
  value       = aws_cloudwatch_dashboard.mwaa.dashboard_name
}

output "mwaa_dashboard_url" {
  description = "URL of the MWAA dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.mwaa.dashboard_name}"
}