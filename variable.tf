variable "aws_region" {
  default = "eu-central-1"
}

variable "db_password" {
  description = "DB Password"
  type        = string
  default     = "db-password"
  sensitive   = true
}

variable "my_ip" {
  description = "My IP"
  type        = string
  default     = "77.255.23.106/32"
}
