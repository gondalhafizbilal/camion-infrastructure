# TF backend deployed and managed via CloudFormation

terraform {
  required_version = ">=1.5.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.13.0"
    }
  }

  backend "s3" {
    bucket         = "camion-terraform-377404936654"
    dynamodb_table = "dynamodb"
    key            = "state/prod.state"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:eu-north-1:377404936654:key/d75a9506-1f05-43fc-9d4e-fd19b07c4934"
    region         = "eu-north-1"
    profile        = "camion-prod"
  }
}
