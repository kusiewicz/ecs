variable "subnet_ids" {
  description = "List of IDs of selected subnets"
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
