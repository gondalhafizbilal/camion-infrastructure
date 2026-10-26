variable "stack_name" {
  description = "The name of the CloudFormation stack"
  type        = string
}

variable "template_path" {
  description = "Path to a local CloudFormation template file (YAML or JSON). Mutually exclusive with template_url."
  type        = string
  default     = null
}

variable "template_url" {
  description = "S3 URL to a CloudFormation template file. Mutually exclusive with template_path."
  type        = string
  default     = null
}

variable "parameters" {
  description = "A map of parameters to pass to the CloudFormation stack"
  type        = map(string)
  default     = {}
}

variable "capabilities" {
  description = "List of capabilities to acknowledge when creating the stack (e.g., CAPABILITY_NAMED_IAM)"
  type        = list(string)
  default     = ["CAPABILITY_NAMED_IAM"]
}

variable "tags" {
  description = "Tags to apply to the CloudFormation stack"
  type        = map(string)
  default     = {}
}

variable "disable_rollback" {
  description = "Set to true to disable rollback of the stack if stack creation fails"
  type        = bool
  default     = false
}

variable "on_failure" {
  description = "Action to be taken if stack creation fails (DO_NOTHING, ROLLBACK, DELETE)"
  type        = string
  default     = "ROLLBACK"
}

variable "timeout_in_minutes" {
  description = "The amount of time that can pass before the stack status becomes CREATE_FAILED"
  type        = number
  default     = 10
}
