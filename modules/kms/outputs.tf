output "s3_key_arn" {
  description = "ARN of the S3 key"
  value       = var.s3 ? aws_kms_key.s3[0].arn : null
}

output "s3_key_id" {
  description = "ID of the S3 key"
  value       = var.s3 ? aws_kms_key.s3[0].id : null
}

output "ebs_key_arn" {
  description = "ARN of the EBS key"
  value       = aws_kms_key.ebs.arn
}

output "ebs_key_id" {
  description = "ID of the EBS key"
  value       = aws_kms_key.ebs.id
}

output "efs_key_arn" {
  description = "ARN of the efs key"
  value       = var.efs ? aws_kms_key.efs[0].arn : null
}

output "efs_key_id" {
  description = "ID of the efs key"
  value       = var.efs ? aws_kms_key.efs[0].id : null
}

output "rds_key_arn" {
  description = "ARN of the RDS key"
  value       = var.rds ? aws_kms_key.rds[0].arn : null
}

output "rds_key_id" {
  description = "ID of the RDS key"
  value       = var.rds ? aws_kms_key.rds[0].id : null
}

output "ssm_key_arn" {
  description = "ARN of the SSM key"
  value       = var.ssm ? aws_kms_key.ssm[0].arn : null
}

output "ssm_key_id" {
  description = "ID of the SSM key"
  value       = var.ssm ? aws_kms_key.ssm[0].id : null
}

output "fsx_key_arn" {
  description = "ARN of the FSx key"
  value       = var.fsx ? aws_kms_key.fsx[0].arn : null
}

output "fsx_key_id" {
  description = "ID of the FSx key"
  value       = var.fsx ? aws_kms_key.fsx[0].id : null
}

output "eks_key_arn" {
  description = "ARN of the EKS key"
  value       = var.eks ? aws_kms_key.eks[0].arn : null
}

output "eks_key_id" {
  description = "ID of the EKS key"
  value       = var.eks ? aws_kms_key.eks[0].id : null
}

output "code_artifact_key_arn" {
  description = "ARN of the code_artifact key"
  value       = var.code_artifact ? aws_kms_key.code_artifact[0].arn : null
}

output "code_artifact_key_id" {
  description = "ID of the code_artifact key"
  value       = var.code_artifact ? aws_kms_key.code_artifact[0].id : null
}

output "ecr_key_arn" {
  description = "ARN of the ECR key"
  value       = var.ecr ? aws_kms_key.ecr[0].arn : null
}

output "ecr_key_id" {
  description = "ID of the ECR key"
  value       = var.ecr ? aws_kms_key.ecr[0].id : null
}

output "sqs_key_arn" {
  description = "ARN of the SQS key"
  value       = var.sqs ? aws_kms_key.sqs[0].arn : null
}

output "sqs_key_id" {
  description = "ID of the SQS key"
  value       = var.sqs ? aws_kms_key.sqs[0].id : null
}

output "elasticache_key_id" {
  description = "ID of the Elasticache key"
  value       = var.elasticache ? aws_kms_key.elasticache[0].id : null
}

output "elasticache_key_arn" {
  description = "ARN of the Elasticache key"
  value       = var.elasticache ? aws_kms_key.elasticache[0].arn : null
}