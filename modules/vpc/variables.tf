variable "availability_zones" {
  description = "List of subnet availability zones."
  type        = list(string)
}

variable "expand_ephemeral_port_range" {
  description = "TCP and UDP ephemeral range will be adjusted to 1024-65535 in private subnets.  Required for Lambda, EKS, etc.  https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html#nacl-ephemeral-ports"
  default     = false
  type        = bool
}

variable "flowlog_retention" {
  description = "Flowlog retention in days for CloudWatch log group."
  default     = 7
  type        = number
}

variable "domain_name" {
  description = "Domain Name"
  default     = "ec2.internal"
  type        = string
}

variable "domain_name_servers" {
  description = "List of the DNS servers"
  default     = ["AmazonProvidedDNS"]
  type        = list(string)
}

variable "flowlog_traffic_type" {
  description = "Type of flowlog traffic to capture.  Valid values - ACCEPT, REJECT, ALL."
  default     = "ALL"
  type        = string
}

variable "settings" {
  description = "Map of desired VPC settings."
  type        = map(any)
}

variable "single_nat_gateway" {
  description = "Single NAT Gateway for all AZs.  Provides cost savings in development environments."
  default     = false
  type        = bool
}

variable "tags" {
  description = "Tags to apply to all VPC resources."
  default     = {}
  type        = map(any)
}

variable "ssm_vpc_endpoint" {
  description = "Enable SSM VPC Endpoint"
  default     = false
  type        = bool
}

variable "create_nat_gateway" {
  description = "Condition to create nat gateway default: true"
  default     = true
  type        = bool
}

variable "create_public_subnet" {
  description = "Condition to create nat gateway default: true"
  default     = true
  type        = bool
}

variable "create_private_subnet" {
  description = "Condition to create nat gateway default: true"
  default     = true
  type        = bool
}

variable "create_private_data_subnet" {
  description = "Condition to create nat gateway default: true"
  default     = true
  type        = bool
}

variable "nat_gateway_ids" {
  description = "Enter nat gateway ids in a list(string) format default: []"
  default = [{
  }]
}
