variable "project_name" {
  type = string
}

variable "private_data_subnet_ids" {
  type = list(string)
}

variable "rds_sg_id" {
  type = string
}

variable "db_engine_version" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "enable_multi_az" {
  type = bool
}

variable "ecs_task_execution_role_arn" {
  type = string
}

variable "codebuild_role_arn" {
  type = string
}

