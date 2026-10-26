resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.vpc.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.vpc.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
}

resource "aws_vpc_endpoint" "ssm_endpoint" {
  count              = var.ssm_vpc_endpoint && local.create_private_subnets ? 1 : 0
  vpc_id             = aws_vpc.vpc.id
  service_name       = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.ssm[0].id]

  subnet_ids = setunion(
    [for subnet in aws_subnet.private : subnet.id]
  )
  private_dns_enabled = true
}
resource "aws_security_group" "ssm" {
  count = var.ssm_vpc_endpoint ? 1 : 0

  name_prefix = "vpc-endpoint-ssm-"
  description = "SSM VPC Endpoint Security Group"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "vpc_endpoint_ssm_https" {
  count = var.ssm_vpc_endpoint ? 1 : 0

  cidr_blocks = [
  var.settings["main"]["cidr"]]
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  security_group_id = aws_security_group.ssm[0].id

}
#
# VPC Endpoint - private data subnet route associations
#

resource "aws_vpc_endpoint_route_table_association" "private_s3_data_cidrs" {
  for_each        = local.create_private_data_subnets ? toset(var.availability_zones) : []
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = aws_route_table.data[each.key].id
}

resource "aws_vpc_endpoint_route_table_association" "private_dynamodb_data_cidrs" {
  for_each        = local.create_private_data_subnets ? toset(var.availability_zones) : []
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb.id
  route_table_id  = aws_route_table.data[each.key].id
}



#
# VPC Endpoints - Private subnet route associations
#

resource "aws_vpc_endpoint_route_table_association" "private_s3_private_cidrs" {
  for_each        = local.create_private_subnets ? toset(var.availability_zones) : []
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = aws_route_table.private[each.key].id
}

resource "aws_vpc_endpoint_route_table_association" "private_dynamodb_private_cidrs" {
  for_each        = local.create_private_subnets ? toset(var.availability_zones) : []
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb.id
  route_table_id  = aws_route_table.private[each.key].id
}

#
# VPC Endpoints - Public route associations
#

resource "aws_vpc_endpoint_route_table_association" "private_s3_public_cidrs" {
  for_each        = local.create_public_subnets ? toset(var.availability_zones) : []
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = aws_route_table.public[each.key].id
}

resource "aws_vpc_endpoint_route_table_association" "private_dynamodb_public_cidrs" {
  for_each        = local.create_public_subnets ? toset(var.availability_zones) : []
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb.id
  route_table_id  = aws_route_table.public[each.key].id
}
