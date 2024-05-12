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
  source = "./modules/networking"
}

module "backend" {
  source     = "./modules/backend"
  subnet_ids = module.networking.subnet_ids
  vpc_id     = module.networking.vpc_id
  var1       = "production"
  my_ip      = "37.14.149.163/32"
}

module "iam" {
  source       = "./modules/iam"
  ecr_arn      = module.backend.ecr_repository_arn
  ecs_task_arn = module.backend.ecs_task_arn
}
