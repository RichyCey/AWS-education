variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "codestar_connection_arn" {
  description = "ARN of an existing CodeStar connection (if empty, a new one is created)"
  type        = string
  default     = ""
}

variable "github_owner" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "github_branch" {
  type    = string
  default = "main"
}

variable "codebuild_role_arn" {
  type = string
}

variable "terraform_codebuild_role_arn" {
  type = string
}

variable "codepipeline_role_arn" {
  type = string
}

variable "codedeploy_role_arn" {
  type = string
}

variable "ecr_repository_url" {
  type = string
}

variable "task_definition_family" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "prod_listener_arn" {
  type = string
}

variable "test_listener_arn" {
  type = string
}

variable "blue_target_group_name" {
  type = string
}

variable "green_target_group_name" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}
