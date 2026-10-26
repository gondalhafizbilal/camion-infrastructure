# ──────────────────────────────────────────────
# App PostgreSQL — Aurora Serverless v2
# ──────────────────────────────────────────────

module "app_postgres" {
  source  = "cloudposse/rds-cluster/aws"
  version = "~> 1.12"

  name = "prod-app-postgres"

  engine         = "aurora-postgresql"
  engine_version = "17.7"
  engine_mode    = "provisioned"
  cluster_family = "aurora-postgresql17"

  # Serverless v2: floor of 4 ACU so a traffic burst does not stall queries
  # while Aurora ramps capacity from a cold start; max 8 ACU keeps cost bounded.
  serverlessv2_scaling_configuration = {
    min_capacity = 4
    max_capacity = 8
  }
  cluster_size  = 1
  instance_type = "db.serverless"

  db_name    = "app"
  admin_user = "masteruser"

  manage_admin_user_password = true

  vpc_id = module.vpc01.id
  subnets = tolist([
    module.vpc01.data_subnet_ids[var.availability_zones[0]],
    module.vpc01.data_subnet_ids[var.availability_zones[1]],
    module.vpc01.data_subnet_ids[var.availability_zones[2]],
  ])
  allowed_cidr_blocks = [module.vpc01.cidr]

  storage_encrypted = true
  kms_key_arn       = module.kms.rds_key_arn

  retention_period                    = 30
  skip_final_snapshot                 = false
  deletion_protection                 = true
  apply_immediately                   = true
  performance_insights_enabled        = true
  iam_database_authentication_enabled = false

  tags = var.common_tags
}
