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

module "ecs" {
  source     = "./modules/ecs"
  subnet_ids = module.networking.subnet_ids
  vpc_id     = module.networking.vpc_id
  var1       = "production"
}

module "iam" {
  source = "./modules/iam"
}
