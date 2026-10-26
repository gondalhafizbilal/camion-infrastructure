variable "aws_region" {
  description = "Terraform deployment region"
  type        = string
}

variable "aws_profile" {
  description = "Local AWS profile used for TF authentication"
  type        = string
}

variable "common_tags" {
  description = "Common tags applied to resources"
  type        = map(string)
}

variable "availability_zones" {
  description = "Availability Zones used by the host VPC"
  type        = list(string)
}

variable "host_vpc_name" {
  description = "Name tag of the VPC the driver tasks attach to (we reuse the dev VPC for egress)"
  type        = string
}

variable "default_target_base_urls" {
  description = "Default fully-qualified base URLs the load test points at. Per-run overrides go via the runner's TARGET_* env vars."
  type = object({
    frontend            = string
    backend             = string
    image_service       = string
    chatbot             = string
    product_translation = string
  })
}

variable "runner" {
  description = "k6 runner Fargate task sizing. CPU/memory caps the VUs per task; total VUs = task_count * vus_per_task."
  type = object({
    cpu          = number
    memory       = number
    vus_per_task = number
    task_count   = number
    duration     = string
  })
}
