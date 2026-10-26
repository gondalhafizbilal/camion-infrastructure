module "app_redis" {
  source  = "cloudposse/elasticache-redis/aws"
  version = "~> 2.0"

  name   = var.app_redis.cluster_name
  engine = "valkey"

  kms_key_id                 = module.kms.elasticache_key_arn
  at_rest_encryption_enabled = var.app_redis.at_rest_encryption_enabled
  port                       = var.app_redis.port
  instance_type              = var.app_redis.node_instance_type
  cluster_size               = var.app_redis.cache_node_count
  automatic_failover_enabled = var.app_redis.automatic_failover_enabled
  engine_version             = var.app_redis.engine_version
  family                     = "valkey7"
  maintenance_window         = var.app_redis.maintenance_window

  create_security_group         = false
  associated_security_group_ids = [aws_security_group.elasticache_redis_sg.id]
  vpc_id                        = module.vpc01.id
  subnets = tolist([
    module.vpc01.data_subnet_ids[var.availability_zones[0]],
    module.vpc01.data_subnet_ids[var.availability_zones[1]],
    module.vpc01.data_subnet_ids[var.availability_zones[2]],
  ])

  tags = var.common_tags
}

module "bullmq_redis" {
  source  = "cloudposse/elasticache-redis/aws"
  version = "~> 2.0"

  name   = var.bullmq_redis.cluster_name
  engine = "valkey"

  kms_key_id                 = module.kms.elasticache_key_arn
  at_rest_encryption_enabled = var.bullmq_redis.at_rest_encryption_enabled
  port                       = var.bullmq_redis.port
  instance_type              = var.bullmq_redis.node_instance_type
  cluster_size               = var.bullmq_redis.cache_node_count
  automatic_failover_enabled = var.bullmq_redis.automatic_failover_enabled
  engine_version             = var.bullmq_redis.engine_version
  family                     = "valkey7"
  maintenance_window         = var.bullmq_redis.maintenance_window

  create_security_group         = false
  associated_security_group_ids = [aws_security_group.elasticache_bullmq_sg.id]
  vpc_id                        = module.vpc01.id
  subnets = tolist([
    module.vpc01.data_subnet_ids[var.availability_zones[0]],
    module.vpc01.data_subnet_ids[var.availability_zones[1]],
    module.vpc01.data_subnet_ids[var.availability_zones[2]],
  ])

  tags = var.common_tags
}

resource "aws_security_group" "elasticache_redis_sg" {
  name        = "${var.app_redis.cluster_name}-sg"
  description = "Security Group for Elasticache Valkey"
  vpc_id      = module.vpc01.id

  ingress {
    description = "Allow inbound traffic on port ${var.app_redis.port} from VPC"
    from_port   = var.app_redis.port
    to_port     = var.app_redis.port
    protocol    = "tcp"
    cidr_blocks = [module.vpc01.cidr]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.aws_profile}-valkey-sg"
  }
}

resource "aws_security_group" "elasticache_bullmq_sg" {
  name        = "${var.bullmq_redis.cluster_name}-sg"
  description = "Security Group for BullMQ Elasticache Valkey"
  vpc_id      = module.vpc01.id

  ingress {
    description = "Allow inbound traffic on port ${var.bullmq_redis.port} from VPC"
    from_port   = var.bullmq_redis.port
    to_port     = var.bullmq_redis.port
    protocol    = "tcp"
    cidr_blocks = [module.vpc01.cidr]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.aws_profile}-bullmq-valkey-sg"
  }
}
