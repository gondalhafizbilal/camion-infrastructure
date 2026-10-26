provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

data "aws_caller_identity" "current" {}

# Reuse the dev VPC for driver egress — load test traffic exits via dev's NAT to the public ALB.
data "aws_vpc" "host" {
  filter {
    name   = "tag:Name"
    values = [var.host_vpc_name]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.host.id]
  }

  filter {
    name   = "tag:Name"
    values = [for az in var.availability_zones : "${var.host_vpc_name}-${az}-private"]
  }
}
