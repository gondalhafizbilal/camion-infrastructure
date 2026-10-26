locals {
  is_aurora = length(split("aurora", var.engine)) > 1
}

resource "aws_rds_cluster" "this" {
  cluster_identifier                  = var.name
  engine                              = var.engine
  engine_version                      = var.engine_version
  kms_key_id                          = var.kms_key_arn != "" ? var.kms_key_arn : null
  database_name                       = var.database_name
  master_username                     = var.master_username
  master_password                     = var.master_password
  final_snapshot_identifier           = var.name
  skip_final_snapshot                 = var.skip_final_snapshot
  deletion_protection                 = var.deletion_protection
  backup_retention_period             = var.snapshot_retention
  preferred_backup_window             = var.backup_window
  preferred_maintenance_window        = var.maintenance_window
  port                                = var.port
  db_subnet_group_name                = aws_db_subnet_group.default.name
  vpc_security_group_ids              = var.security_group_ids == [""] ? ["aws_security_group.default.id"] : concat(var.security_group_ids, [aws_security_group.default.id])
  storage_encrypted                   = var.kms_key_arn != "" ? true : false
  apply_immediately                   = var.apply_immediately
  db_cluster_parameter_group_name     = aws_rds_cluster_parameter_group.default.name

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  tags = merge(var.tags, { "Name" = var.name })
}

resource "aws_rds_cluster_instance" "this" {
  identifier                      = var.name
  ca_cert_identifier              = var.ca_cert_identifier
  cluster_identifier              = aws_rds_cluster.this.id
  engine                          = var.engine
  engine_version                  = var.engine_version
  instance_class                  = var.db_instance_class
  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_enabled ? var.performance_insights_kms_key_id : null
  publicly_accessible             = var.publicly_accessible
}

resource "aws_rds_cluster_instance" "replicas" {
  count = var.replica_count

  identifier                      = "${var.name}-replica-${count.index + 1}"
  ca_cert_identifier              = var.ca_cert_identifier
  cluster_identifier              = aws_rds_cluster.this.id
  engine                          = var.engine
  engine_version                  = var.engine_version
  instance_class                  = var.db_instance_class
  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_enabled ? var.performance_insights_kms_key_id : null
  publicly_accessible             = var.publicly_accessible
}

resource "aws_rds_cluster_parameter_group" "default" {
  name        = "${var.name}-cluster-parameter-group"
  family      = var.family
  description = "${var.name}cluster-parameter-group"
}

resource "aws_db_parameter_group" "default" {
  name   = var.name
  family = var.family
  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = lookup(parameter.value, "apply_method", null)
    }
  }
  tags = merge(var.tags, { "Name" = var.name })
}

resource "aws_db_subnet_group" "default" {
  name       = var.name
  subnet_ids = var.subnets

  tags = merge(var.tags, { "Name" = var.name })
}

resource "aws_security_group" "default" {
  name_prefix = "rds-${var.name}-sg"
  description = "Controls access to ${var.name} RDS instance"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { "Name" = "rds-${var.name}" })
}

resource "aws_security_group_rule" "ingress_vpc" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = var.ingress_cidrs
  security_group_id = aws_security_group.default.id
  description       = "Ingress access from within the VPC."
}

resource "aws_security_group_rule" "egress_full" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default.id
  description       = "Egress access to everywhere."
}
