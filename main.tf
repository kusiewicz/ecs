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
  first_private_subnet_cidr  = "10.0.3.0/24"
  second_private_subnet_cidr = "10.0.4.0/24"
  first_availability_zone    = "eu-central-1a"
  second_availability_zone   = "eu-central-1b"
}

module "backend" {
  source             = "./modules/backend"
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
  vpc_id             = module.networking.vpc_id
  var1               = "production"
  my_ip              = "78.8.133.132/32"
}

module "iam" {
  source       = "./modules/iam"
  ecr_arn      = module.backend.ecr_repository_arn
  ecs_task_arn = module.backend.ecs_task_arn
}
