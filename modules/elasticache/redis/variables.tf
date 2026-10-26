variable "cluster_name" {
  description = "Name of EC cluster (must contain only lowercase, alphanumeric characters, and hyphens)"
  type        = string
}

variable "description" {
  description = "Description for the Cluster"
  default     = ""
  type        = string
}

variable "kms_key_id" {
  description = "The ARN of the key that you wish to use if encrypting at rest. If not supplied, uses service managed encryption. Can be specified only if at_rest_encryption_enabled = true"
  default     = null
  type        = string
}

variable "node_instance_type" {
  description = "Instance type for Redis nodes"
  default     = "cache.t3.small"
  type        = string
}

variable "cache_node_count" {
  description = "Number of Redis Nodes"
  default     = 2
  type        = number
}

variable "automatic_failover_enabled" {
  description = "whether a read-only replica will be automatically promoted to read/write primary if the existing primary fails."
  default     = false
  type        = bool
}

variable "engine_version" {
  description = "Cluster engine version"
  default     = "7.0"
  type        = string
}

variable "port" {
  description = "Port number for EC endpoint"
  default     = 6379
  type        = number
}

variable "maintenance_window" {
  description = "Weekly time-range to perform maintenance on the cluster (Time is in 24H UTC Clock)"
  default     = "fri:08:00-fri:09:00"
  type        = string
}

variable "at_rest_encryption_enabled" {
  description = "Whether to enable encryption at rest."
  default     = true
}

variable "snapshot_window" {
  description = "Daily time-range to perform snapshot backups on the cluster (Time is in 24H UTC Clock)"
  default     = "06:00-07:00"
  type        = string
}

variable "subnets" {
  description = "List of subnets to associate with the Elasticache Cluster e.g. ['subnet-1a2b3c4d','subnet-1a2b3c4e','subnet-1a2b3c4f']"
  default     = null
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group ids to associate with the Elasticache Cluster e.g. ['sg-1a2b3c4d','sg-1a2b3c4e','sg-1a2b3c4f']"
  default     = null
  type        = list(string)
}


variable "tags" {
  description = "Tags to apply to all module resources."
  default     = {}
  type        = map(any)
}
