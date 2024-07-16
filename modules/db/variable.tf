variable "db_first_subnet_group_id" {
  description = "ID of the first DB subnet group"
  type        = string
}

variable "db_second_subnet_group_id" {
  description = "ID of the second DB subnet group"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the selected VPC"
  type        = string
}

variable "ecs_security_group_id" {
  description = "ID of the ECS security group"
  type        = string
}

variable "db_password" {
  description = "The password for the DB"
  type        = string
}

variable "my_ip" {
  description = "My IP"
  type        = string
}

variable "bastion_ami" {
  description = "The AMI for the bastion host"
  type        = string
}

variable "bastion_subnet" {
  description = "The subnet for the bastion host"
  type        = string
}
