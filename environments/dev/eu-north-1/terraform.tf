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
    bucket         = "camion-terraform-167781471441"
    dynamodb_table = "dynamodb"
    key            = "state/dev.state"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:eu-north-1:167781471441:key/7f7374f0-740a-4f61-b738-456c238c647b"
    region         = "eu-north-1"
    profile        = "camion-dev"
  }
}