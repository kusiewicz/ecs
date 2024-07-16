variable "public_subnet_ids" {
  description = "List of IDs of selected public subnets"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of IDs of selected private subnets"
  type        = list(string)
}

variable "vpc_id" {
  description = "The ID of the selected VPC"
  type        = string
}

variable "var1" {
  description = "Environment variable"
  type        = string
}

variable "my_ip" {
  description = "My IP address"
  type        = string
}

variable "db_password" {
  description = "The password for the DB"
  type        = string
}
