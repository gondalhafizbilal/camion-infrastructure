#
#  Subnet with default route to a NAT gateway located in a public subnet.
#  NACLs open to VPC CIDR, TCP and UDP Linux ephemeral port range to 0.0.0.0/0.
#  VPC Endpoints for S3 and DynamoDB
#

resource "aws_subnet" "private" {
  for_each          = local.create_private_subnets ? toset(var.availability_zones) : []
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.settings[each.key]["cidr_private"]
  availability_zone = each.key

  tags = merge(var.tags, {
    "Name"                            = "${var.settings["main"]["name"]}-${each.key}-private",
    "kubernetes.io/role/internal-elb" = "1"
  })
}

#
# Route Resources
#

resource "aws_route_table" "private" {
  for_each = local.create_private_subnets ? toset(var.availability_zones) : []
  vpc_id   = aws_vpc.vpc.id

  tags = merge(var.tags, {
    "Name" = "${var.settings["main"]["name"]}-${each.key}-private"
  })
}

resource "aws_route_table_association" "private" {
  for_each       = local.create_private_subnets ? toset(var.availability_zones) : []
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_route" "nat_gw" {
  for_each               = local.create_private_subnets ? toset(var.availability_zones) : []
  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.create_nat_gateway ? (var.single_nat_gateway ? aws_nat_gateway.nat_gw[var.availability_zones[0]].id : aws_nat_gateway.nat_gw[each.key].id) : var.nat_gateway_ids[each.key]
}

#
# NACLs - rules should remain outside aws_network_acl to avoid resource number collisions
#

resource "aws_network_acl" "private" {
  for_each   = local.create_private_subnets ? toset(var.availability_zones) : []
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = tolist([aws_subnet.private[each.key].id])

  tags = merge(var.tags, { "Name" = "${var.settings["main"]["name"]}-${each.key}-private" },
  { "kubernetes.io/role/internal-elb" = "1" })
}

# ingress rules
resource "aws_network_acl_rule" "private_ingress100" {
  for_each       = local.create_private_subnets ? toset(var.availability_zones) : []
  network_acl_id = aws_network_acl.private[each.key].id
  egress         = false
  protocol       = "-1"
  rule_number    = 100
  rule_action    = "allow"
  cidr_block     = var.settings["main"]["cidr"]
  from_port      = 0
  to_port        = 0
}

# UDP Linux ephemeral port range (includes windows)
resource "aws_network_acl_rule" "private_ingress200" {
  for_each       = local.create_private_subnets ? toset(var.availability_zones) : []
  network_acl_id = aws_network_acl.private[each.key].id
  egress         = false
  protocol       = "udp"
  rule_number    = 200
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = var.expand_ephemeral_port_range ? 1024 : 32768
  to_port        = 65535
}

# TCP Linux ephemeral port range (includes windows)
resource "aws_network_acl_rule" "private_ingress300" {
  for_each       = local.create_private_subnets ? toset(var.availability_zones) : []
  network_acl_id = aws_network_acl.private[each.key].id
  egress         = false
  protocol       = "tcp"
  rule_number    = 300
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = var.expand_ephemeral_port_range ? 1024 : 32768
  to_port        = 65535
}

# egress rules
resource "aws_network_acl_rule" "private_egress100" {
  for_each       = local.create_private_subnets ? toset(var.availability_zones) : []
  network_acl_id = aws_network_acl.private[each.key].id
  egress         = true
  protocol       = "-1"
  rule_number    = 100
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}
