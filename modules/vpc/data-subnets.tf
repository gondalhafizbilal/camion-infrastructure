#
#  Subnet with no default route.
#  NACLs open to VPC CIDR only.
#  VPC Endpoints for S3 and DynamoDB
#

resource "aws_subnet" "data" {
  for_each          = local.create_private_data_subnets ? toset(var.availability_zones) : []
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.settings[each.key]["cidr_data"]
  availability_zone = each.key

  tags = merge(var.tags, { "Name" = "${var.settings["main"]["name"]}-${each.key}-data" })
}

#
# Route Resources
#

resource "aws_route_table" "data" {
  for_each = local.create_private_data_subnets ? toset(var.availability_zones) : []
  vpc_id   = aws_vpc.vpc.id

  tags = merge(var.tags, { "Name" = "${var.settings["main"]["name"]}-${each.key}-data" })
}

resource "aws_route_table_association" "data" {
  for_each       = local.create_private_data_subnets ? toset(var.availability_zones) : []
  subnet_id      = aws_subnet.data[each.key].id
  route_table_id = aws_route_table.data[each.key].id
}

#
# NACLs - rules should remain outside aws_network_acl to avoid resource number collisions
#

resource "aws_network_acl" "data" {
  for_each   = local.create_private_data_subnets ? toset(var.availability_zones) : []
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = tolist([aws_subnet.data[each.key].id])

  tags = merge(var.tags, { "Name" = "${var.settings["main"]["name"]}-${each.key}-data" })
}

# ingress rules
resource "aws_network_acl_rule" "data_ingress100" {
  for_each       = local.create_private_data_subnets ? toset(var.availability_zones) : []
  network_acl_id = aws_network_acl.data[each.key].id
  egress         = false
  protocol       = "-1"
  rule_number    = 100
  rule_action    = "allow"
  cidr_block     = var.settings["main"]["cidr"]
  from_port      = 0
  to_port        = 0
}

# egress rules
resource "aws_network_acl_rule" "data_egress100" {
  for_each       = local.create_private_data_subnets ? toset(var.availability_zones) : []
  network_acl_id = aws_network_acl.data[each.key].id
  egress         = true
  protocol       = "-1"
  rule_number    = 100
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}
