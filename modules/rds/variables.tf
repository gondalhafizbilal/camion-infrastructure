variable "backup_window" {
  description = "Backup window in UTC"
  default     = "05:00-06:00"
  type        = string
}

variable "database_name" {
  description = "Database to create at instance launch time."
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Prevent accidental instance deletion"
  default     = true
  type        = bool
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of logs to push to CloudWatch Logs"
  default     = []
  type        = list(string)
}

variable "engine" {
  description = "Database engine"
  type        = string
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
}

variable "family" {
  description = "Database family"
  type        = string
}

variable "ingress_cidrs" {
  description = "List of CIDRs to be allowed TCP access to the instance."
  type        = list(string)
}

variable "kms_key_arn" {
  description = "KMS Key ARN for encryption.  An explicit empty value will *disable* encryption."
  type        = string
}

variable "maintenance_window" {
  description = "Maintenance window in UTC"
  default     = "sun:06:00-sun:07:00"
  type        = string
}

variable "master_username" {
  description = "Master username"
  type        = string
}

variable "master_password" {
  description = "Master Password"
  type        = string
}

variable "name" {
  description = "Name - used for cluster, instance, security group, subnet group, and parameter groups."
  type        = string
}

variable "performance_insights_enabled" {
  description = "Specifies whether Performance Insights is enabled or not."
  type        = bool
  default     = false
}

variable "performance_insights_kms_key_id" {
  description = "ARN for the KMS key to encrypt Performance Insights data."
  type        = string
  default     = null
}

variable "port" {
  description = "Port to listen on."
  type        = number
}

variable "snapshot_retention" {
  description = "Snapshot retention in days.  Max - 35"
  default     = 7
  type        = number
}

variable "security_group_ids" {
  description = "List of additional security group IDs to associate with the cluster."
  default     = []
  type        = list(string)
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on termination"
  default     = false
  type        = bool
}

variable "subnets" {
  description = "List of private subnets to deploy the cluster in."
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to all stack resources."
  default     = {}
  type        = map(string)
}

variable "db_instance_class" {
  description = "Instance class for the rds database to run on"
  default     = "db.t3.small"
  type        = string
}

variable "storage_type" {
  description = "Storage Type for db instance"
  default     = "gp2"
  type        = string
}

variable "allocated_storage" {
  description = "Storage Size"
  default     = 20
  type        = number
}

variable "multi_az" {
  description = "Bool if the database should be in multi az"
  type        = bool
  default     = false
}

variable "public_access" {
  description = "Bool if the database can be publicly accesable"
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Bool if the changes will apply immediately"
  type        = bool
  default     = true
}

variable "parameters" {
  description = "A list of DB parameter maps to apply"
  type        = list(map(string))
  default     = []
}

variable "vpc_id" {
  type = string
}

variable "license_model" {
  type = string
}

variable "ca_cert_identifier" {
  description = "Specifies the identifier of the CA certificate for the DB instance"
  type        = string
  default     = null
}

variable "publicly_accessible" {
  type = string
}

variable "replica_count" {
  description = "Number of read replica instances to create"
  type        = number
  default     = 0
}