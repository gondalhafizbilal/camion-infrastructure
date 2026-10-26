variable "s3" {
  description = "Enable customer managed KMS key for use with s3 buckets"
  default     = false
  type        = bool
}

variable "ebs" {
  description = "Enable customer managed KMS key for use with EBS volumes"
  default     = false
  type        = bool
}

variable "efs" {
  description = "Enable customer managed KMS key for use with EFS"
  default     = false
  type        = bool
}

variable "ecr" {
  description = "Enable customer managed KMS key for use with ecr repository"
  default     = false
  type        = bool
}

variable "kms_key_rotation" {
  description = "AWS managed rotation of KMS key.  Occurs automatically each year."
  default     = false
  type        = bool
}

variable "kms_key_deletion_window_in_days" {
  description = "Number of days before a key is removed after being marked for deletion.  7-30 days."
  default     = 30
  type        = number
}

variable "rds" {
  description = "Enable customer managed KMS key for RDS"
  default     = false
  type        = bool
}

variable "service_linked_role_spot_arn" {
  description = "Spot service linked role ARN.  If supplied, proper access to the EBS key will be granted."
  default     = ""
  type        = string
}

variable "service_role_batch_arn" {
  description = "Batch service role ARN.  If supplied, proper access to the EBS key will be granted."
  default     = ""
  type        = string
}

variable "service_role_spot_fleet_arn" {
  description = "Spot Fleet service role ARN.  If supplied, proper access to the EBS key will be granted."
  default     = ""
  type        = string
}
variable "service_role_autoscaling_arn" {
  description = "Autoscaling service role ARN.  If supplied, proper access to the EBS key will be granted."
  default     = ""
  type        = string
}

variable "ssm" {
  description = "Enable customer managed KMS key for SSM"
  default     = false
  type        = bool
}

variable "fsx" {
  description = "Enable customer managed KMS key for FSx"
  default     = false
  type        = bool
}

variable "eks" {
  description = "Enable customer managed KMS key for EKS"
  default     = false
  type        = bool
}

variable "sqs" {
  description = "Enable customer managed KMS key for SQS"
  default     = false
  type        = bool
}
variable "elasticache" {
  description = "Enable customer managed KMS key for Elasticache"
  default     = false
  type        = bool
}
variable "code_artifact" {
  description = "Enable customer managed KMS key for Code Artifact"
  default     = false
  type        = bool
}

variable "tags" {
  description = "Tags to apply to all module resources."
  default     = {}
  type        = map(any)
}
