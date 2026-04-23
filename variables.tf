# variables.tf — Define all configurable values here

variable "aws_region" {
  description = "AWS region to deploy resources"
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.1.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.1.1.0/24"
}

variable "private_subnet_1_cidr" {
  default = "10.1.2.0/24"
}

variable "private_subnet_2_cidr" {
  default = "10.1.3.0/24"
}

variable "db_password" {
  description = "Master password for RDS MySQL"
  default     = "Admin1234"
  sensitive   = true # hides value from terraform plan output
}

variable "db_name" {
  default = "studentdb"
}

variable "key_pair_name" {
  description = "Name of existing EC2 key pair"
  default     = "my-key"
}
