variable "region" {
  type        = string
  description = "The region to deploy resources in"
}

variable "environment_name" {
  type        = string
  description = "Name used to create and tag resources"
}

variable "vpc_cidr" {
  type        = string
  description = "The IP range for the VPC in CIDR format"
}

variable "rds_name" {
  description = "Database name"
  type        = string
}

variable "rds_username" {
  description = "Username for PostgreSQL database"
  type        = string
}

variable "rds_password" {
  description = "Password for PostgreSQL database"
  type        = string
}