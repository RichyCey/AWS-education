variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_app_subnet_ids" {
  type = list(string)
}

variable "alb_sg_id" {
  type = string
}

variable "app_sg_id" {
  type = string
}

variable "ecs_task_execution_role_arn" {
  type = string
}

variable "ecs_task_role_arn" {
  type = string
}

variable "db_credentials_secret_arn" {
  type = string
}

variable "ecr_repository_url" {
  type = string
}

variable "ollama_image_tag" {
  type = string
}

variable "ecs_desired_count" {
  type = number
}

variable "ecs_max_count" {
  description = "Maximum number of ECS tasks for auto-scaling"
  type        = number
  default     = 4
}
