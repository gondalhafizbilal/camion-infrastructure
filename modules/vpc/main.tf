data "aws_region" "current" {}
locals {
  create_private_subnets      = [for r in var.availability_zones : lookup(var.settings[r], "cidr_private", null)][0] != null
  create_public_subnets       = [for r in var.availability_zones : lookup(var.settings[r], "cidr_public", null)][0] != null
  create_private_data_subnets = [for r in var.availability_zones : lookup(var.settings[r], "cidr_data", null)][0] != null

}
resource "aws_vpc" "vpc" {
  cidr_block           = var.settings["main"]["cidr"]
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { "Name" = var.settings["main"]["name"] })
}

resource "aws_flow_log" "flowlogs" {
  log_destination = aws_cloudwatch_log_group.flowlogs.arn
  iam_role_arn    = aws_iam_role.flowlogs.arn
  vpc_id          = aws_vpc.vpc.id
  traffic_type    = var.flowlog_traffic_type
}

resource "aws_cloudwatch_log_group" "flowlogs" {
  name              = "/aws/flowlogs/${var.settings["main"]["name"]}"
  retention_in_days = var.flowlog_retention
  tags              = merge(var.tags, { "Name" = var.settings["main"]["name"] })
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { "Name" = var.settings["main"]["name"] })
}

resource "aws_vpc_dhcp_options" "options" {
  domain_name         = var.domain_name
  domain_name_servers = var.domain_name_servers
  tags                = merge(var.tags, { "Name" = var.settings["main"]["name"] })
}

resource "aws_vpc_dhcp_options_association" "association" {
  vpc_id          = aws_vpc.vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.options.id
}
