#
#  Subnet with default route to a Internet gateway.
#  NACLs open to 0.0.0.0/0.
#  VPC Endpoints for S3 and DynamoDB
#

resource "aws_subnet" "public" {
  for_each                = local.create_public_subnets ? toset(var.availability_zones) : []
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.settings[each.key]["cidr_public"]
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    "Name"                   = "${var.settings["main"]["name"]}-${each.key}-public",
    "kubernetes.io/role/elb" = "1"

  })
}

#
# Route Resources
#

resource "aws_route_table" "public" {
  for_each = local.create_public_subnets ? toset(var.availability_zones) : []
  vpc_id   = aws_vpc.vpc.id

  tags = merge(var.tags, {
    "Name" = "${var.settings["main"]["name"]}-${each.key}-public"
  })
}

resource "aws_route_table_association" "public" {
  for_each       = local.create_public_subnets ? toset(var.availability_zones) : []
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[each.key].id
}

resource "aws_route" "igw" {
  for_each               = local.create_public_subnets ? toset(var.availability_zones) : []
  route_table_id         = aws_route_table.public[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

#
# NACLs - rules should remain outside aws_network_acl to avoid resource number collisions
#

resource "aws_network_acl" "public" {
  for_each   = local.create_public_subnets ? toset(var.availability_zones) : []
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = [aws_subnet.public[each.key].id]

  tags = merge(var.tags, { "Name" = "${var.settings["main"]["name"]}-${each.key}-public" })
}

# ingress rules
resource "aws_network_acl_rule" "public_ingress100" {
  for_each       = local.create_public_subnets ? toset(var.availability_zones) : []
  network_acl_id = aws_network_acl.public[each.key].id
  egress         = false
  protocol       = "-1"
  rule_number    = 100
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# egress rules
resource "aws_network_acl_rule" "public_egress100" {
  for_each       = local.create_public_subnets ? toset(var.availability_zones) : []
  network_acl_id = aws_network_acl.public[each.key].id
  egress         = true
  protocol       = "-1"
  rule_number    = 100
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

#
# NAT Gateway
#

resource "aws_eip" "nat_gw" {
  for_each = var.create_nat_gateway && local.create_public_subnets ? (var.single_nat_gateway ? [var.availability_zones[0]] : toset(var.availability_zones)) : []
}

resource "aws_nat_gateway" "nat_gw" {
  for_each      = var.create_nat_gateway && local.create_public_subnets ? (var.single_nat_gateway ? [var.availability_zones[0]] : toset(var.availability_zones)) : []
  allocation_id = aws_eip.nat_gw[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(var.tags, { "Name" = "${var.settings["main"]["name"]}-${each.key}-public" })
}
