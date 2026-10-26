output "profile_ec2_ssm_arn" {
  description = "ARN of the ec2-ssm instance profile"
  value       = var.role_ec2_ssm ? aws_iam_instance_profile.ec2_ssm[0].arn : null
}

output "role_ec2_ssm_name" {
  description = "Name of the ec2-ssm role"
  value       = var.role_ec2_ssm ? aws_iam_role.ec2_ssm[0].name : null
}

output "role_api_gateway_name" {
  description = "Name of the api-gateway role"
  value       = var.role_api_gateway ? aws_iam_role.api_gateway[0].name : null
}

output "role_api_gateway_arn" {
  description = "ARN of the api-gateway role"
  value       = var.role_api_gateway ? aws_iam_role.api_gateway[0].arn : null
}

output "service_linked_role_autoscaling_arn" {
  description = "ARN of the autoscaling service linked role"
  value       = aws_iam_service_linked_role.autoscaling.arn
}

# output "service_linked_role_rds_arn" {
#   description = "ARN of the RDS service linked role"
#   value       = aws_iam_service_linked_role.rds.arn
# }

output "service_linked_role_spot_arn" {
  description = "ARN of the Spot service linked role"
  value       = aws_iam_service_linked_role.spot.arn
}

output "service_role_cloudformation_arn" {
  description = "ARN of the Cloudformation service role"
  value       = var.role_cloudformation ? aws_iam_role.cloudformation[0].arn : null
}

output "service_role_cloudformation_name" {
  description = "Name of the Cloudformation service role"
  value       = var.role_cloudformation ? aws_iam_role.cloudformation[0].name : null
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions OIDC deployment role"
  value       = var.github_oidc_enabled ? aws_iam_role.github_actions[0].arn : null
}

output "github_actions_user_access_key" {
  value       = try(aws_iam_access_key.publisher[0].id, null)
  description = "AWS_ACCESS_KEY to deploy to ECS"
}

output "github_actions_user_secret_key" {
  value       = try(aws_iam_access_key.publisher[0].secret, null)
  description = "AWS_SECRET_ACCESS_KEY to deploy to ECS"
  sensitive   = true
}