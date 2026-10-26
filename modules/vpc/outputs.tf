output "id" {
  value       = aws_vpc.vpc.id
  description = "VPC ID"
}

output "cidr" {
  value       = aws_vpc.vpc.cidr_block
  description = "VPC CIDR"
}

#
# NAT Gateways
#

output "nat_gateway_ids" {
  value       = var.create_nat_gateway ? { for k, v in aws_nat_gateway.nat_gw : k => v.id } : null
  description = "NAT Gateway IDs"
}

output "nat_gateway_public_ips" {
  value       = var.create_nat_gateway ? { for k, v in aws_nat_gateway.nat_gw : k => v.public_ip } : null
  description = "NAT Gateway IDs"
}

#
# Public Subnets
#

output "public_network_acl" {
  value       = var.create_public_subnet ? { for k, v in aws_network_acl.public : k => v.id } : null
  description = "Public subnet NACLs"
}

output "public_route_tables" {
  value       = var.create_public_subnet ? { for k, v in aws_route_table.public : k => v.id } : null
  description = "Public subnet route tables"
}

output "public_subnet_ids" {
  value       = var.create_public_subnet ? { for k, v in aws_subnet.public : k => v.id } : null
  description = "Public subnet IDs"
}

output "public_subnet_cidrs" {
  value       = var.create_public_subnet ? { for k, v in aws_subnet.public : k => v.cidr_block } : null
  description = "Public subnet CIDRs"
}

#
# Private subnets
#

output "private_network_acl" {
  value       = var.create_private_subnet ? { for k, v in aws_network_acl.private : k => v.id } : null
  description = "Private subnet NACLs"
}

output "private_route_tables" {
  value       = var.create_private_subnet ? { for k, v in aws_route_table.private : k => v.id } : null
  description = "Private subnet route tables"
}

output "private_subnet_ids" {
  value       = var.create_private_subnet ? { for k, v in aws_subnet.private : k => v.id } : null
  description = "Private subnet IDs"
}

output "private_subnet_cidrs" {
  value       = var.create_private_subnet ? { for k, v in aws_subnet.private : k => v.cidr_block } : null
  description = "Private subnet CIDRs"
}

#
# Data subnets
#

output "data_network_acl" {
  value       = var.create_private_data_subnet ? { for k, v in aws_network_acl.data : k => v.id } : null
  description = "Data subnet NACLs"
}

output "data_route_tables" {
  value       = var.create_private_data_subnet ? { for k, v in aws_route_table.data : k => v.id } : null
  description = "Data subnet route tables"
}

output "data_subnet_ids" {
  value       = var.create_private_data_subnet ? { for k, v in aws_subnet.data : k => v.id } : null
  description = "Data subnet IDs"
}

output "data_subnet_cidrs" {
  value       = var.create_private_data_subnet ? { for k, v in aws_subnet.data : k => v.cidr_block } : null
  description = "Data subnet CIDRs"
}
