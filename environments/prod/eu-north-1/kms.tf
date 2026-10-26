module "kms" {
  source                       = "../../../modules/kms"
  ssm                          = true
  kms_key_rotation             = true
  rds                          = true
  s3                           = true
  ecr                          = true
  elasticache                  = true
  service_role_autoscaling_arn = module.iam.service_linked_role_autoscaling_arn
  tags                         = var.common_tags
}
