module "vpc01" {
  source             = "../../../modules/vpc"
  availability_zones = var.availability_zones
  single_nat_gateway = true
  settings = {
    main = {
      name   = var.vpc01_name
      cidr   = var.vpc01_cidr
      region = var.aws_region
    }
    (var.availability_zones[0]) = {
      cidr_public  = var.vpc01_public_cidr_az01
      cidr_private = var.vpc01_private_cidr_az01
      cidr_data    = var.vpc01_data_cidr_az01
    }
    (var.availability_zones[1]) = {
      cidr_public  = var.vpc01_public_cidr_az02
      cidr_private = var.vpc01_private_cidr_az02
      cidr_data    = var.vpc01_data_cidr_az02
    }
    (var.availability_zones[2]) = {
      cidr_public  = var.vpc01_public_cidr_az03
      cidr_private = var.vpc01_private_cidr_az03
      cidr_data    = var.vpc01_data_cidr_az03
    }
  }
  tags = var.common_tags
}