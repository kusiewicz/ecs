terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "networking" {
  source                     = "./modules/networking"
  first_public_subnet_cidr   = "10.0.1.0/24"
  second_public_subnet_cidr  = "10.0.2.0/24"
  third_public_subnet_cidr   = "10.0.7.0/24"
  first_private_subnet_cidr  = "10.0.3.0/24"
  second_private_subnet_cidr = "10.0.4.0/24"
  third_private_subnet_cidr  = "10.0.5.0/24"
  fourth_private_subnet_cidr = "10.0.6.0/24"
  first_availability_zone    = "eu-central-1a"
  second_availability_zone   = "eu-central-1b"
  third_availability_zone    = "eu-central-1c"
}

module "backend" {
  source             = "./modules/backend"
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
  vpc_id             = module.networking.vpc_id
  var1               = "production"
  my_ip              = var.my_ip
  db_password        = var.db_password
}

module "iam" {
  source       = "./modules/iam"
  ecr_arn      = module.backend.ecr_repository_arn
  ecs_task_arn = module.backend.ecs_task_arn
}

module "db" {
  source                    = "./modules/db"
  vpc_id                    = module.networking.vpc_id
  ecs_security_group_id     = module.backend.ecs_security_group_id
  db_first_subnet_group_id  = module.networking.private_subnet_ids[2]
  db_second_subnet_group_id = module.networking.private_subnet_ids[3]
  db_password               = var.db_password
  bastion_ami               = "ami-0346fd83e3383dcb4"
  bastion_subnet            = module.networking.first_public_subnet_id
  my_ip                     = var.my_ip
}
