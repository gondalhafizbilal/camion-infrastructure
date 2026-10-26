
variable "role_api_gateway" {
  description = "Create cloudwatch service role and cloudwatch role"
  default     = false
  type        = bool
}


variable "role_cloudformation" {
  description = "Create cloudformation service role"
  default     = false
  type        = bool
}

variable "role_ec2_ssm" {
  description = "Create role with SSM core policy attached"
  default     = false
  type        = bool
}

variable "user_ecs_github" {
  description = "Create user to deploy application to ECS."
  default     = false
}

variable "ssm_kms_key_id" {
  description = "Encrypt user access key for Github Actions user."
  default     = null
}

variable "github_oidc_enabled" {
  description = "Create GitHub Actions OIDC provider and deployment role."
  default     = false
  type        = bool
}

variable "github_org" {
  description = "GitHub organisation (e.g. CamionOfficial)."
  default     = ""
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (e.g. camion-backend-v2)."
  default     = ""
  type        = string
}

variable "github_branch" {
  description = "Branch allowed to assume the deployment role."
  default     = "dev"
  type        = string
}

variable "github_oidc_role_policies" {
  description = "Map of policy ARNs to attach to the GitHub Actions deployment role."
  default     = {}
  type        = map(string)
}

variable "tags" {
  description = "Tags to apply to all module resources."
  default     = {}
  type        = map(any)
}
