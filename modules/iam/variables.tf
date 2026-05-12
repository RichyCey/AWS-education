variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "db_credentials_secret_arn" {
  type = string
}

variable "rds_resource_id" {
  type = string
}

variable "db_username" {
  type      = string
  sensitive = true
}
