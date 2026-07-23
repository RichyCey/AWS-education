variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "private_app_subnet_ids" {
  type = list(string)
}

variable "lambda_sg_id" {
  type = string
}

variable "alb_dns_name" {
  type = string
}

variable "db_credentials_secret_arn" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "db_allocated_storage_gb" {
  type    = number
  default = 20
}
