variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name used for tagging and naming"
  type        = string
  default     = "my-app"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private application subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "private_data_subnet_cidrs" {
  description = "CIDR blocks for private data subnets"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "enable_multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = false
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.17"
}

variable "state_bucket_name" {
  description = "S3 bucket name for Terraform state"
  type        = string
  default     = "my-terraform-state-bucket"
}

variable "ecs_desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 2
}

variable "ollama_image_tag" {
  description = "Tag for the Ollama ECR image"
  type        = string
  default     = "v1"
}

variable "ecs_max_count" {
  description = "Maximum number of ECS tasks for auto-scaling"
  type        = number
  default     = 4
}

# ------------------------------------------------------------------------------
# CI/CD Variables
# ------------------------------------------------------------------------------

variable "deploy_cicd" {
  description = "Deploy CI/CD pipelines (requires github_owner and github_repo)"
  type        = bool
  default     = true
}

variable "codestar_connection_arn" {
  description = "ARN of an existing CodeStar connection to GitHub (leave empty to create a new one)"
  type        = string
  default     = ""
}

variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = "RichyCey"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "AWS-education"
}

variable "github_branch" {
  description = "GitHub branch to track for CI/CD"
  type        = string
  default     = "master"
}

variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications (leave empty to skip)"
  type        = string
  default     = "rogommy.sw@gmail.com"
}

# ------------------------------------------------------------------------------
# Lambda Variables
# ------------------------------------------------------------------------------

variable "deploy_lambda" {
  description = "Deploy Lambda health monitor"
  type        = bool
  default     = true
}
