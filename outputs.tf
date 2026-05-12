output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "IDs of private application subnets"
  value       = module.networking.private_app_subnet_ids
}

output "private_data_subnet_ids" {
  description = "IDs of private data subnets"
  value       = module.networking.private_data_subnet_ids
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = module.security.alb_sg_id
}

output "app_security_group_id" {
  description = "ID of the application tier security group"
  value       = module.security.app_sg_id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = module.security.rds_sg_id
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.rds_endpoint
}

output "rds_address" {
  description = "RDS instance address (hostname only)"
  value       = module.database.rds_address
}

output "db_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret for DB credentials"
  value       = module.database.db_credentials_secret_arn
}

output "codebuild_role_arn" {
  description = "ARN of the CodeBuild IAM role"
  value       = module.iam.codebuild_role_arn
}

output "codepipeline_role_arn" {
  description = "ARN of the CodePipeline IAM role"
  value       = module.iam.codepipeline_role_arn
}

output "codedeploy_role_arn" {
  description = "ARN of the CodeDeploy IAM role"
  value       = module.iam.codedeploy_role_arn
}

output "nat_gateway_ip" {
  description = "Elastic IP of the NAT Gateway"
  value       = module.networking.nat_gateway_ip
}

output "alb_dns_name" {
  description = "DNS name of the ALB (use this to access Open WebUI)"
  value       = module.ecs.alb_dns_name
}

output "ecr_repository_url" {
  description = "ECR repository URL for Ollama image"
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.service_name
}

output "sns_alerts_topic_arn" {
  description = "ARN of the SNS topic for CloudWatch alarms"
  value       = module.monitoring.sns_topic_arn
}

# ------------------------------------------------------------------------------
# CI/CD Outputs
# ------------------------------------------------------------------------------

output "codestar_connection_arn" {
  description = "ARN of the CodeStar connection (complete setup in AWS Console)"
  value       = var.deploy_cicd ? module.cicd[0].codestar_connection_arn : null
}

output "infra_pipeline_name" {
  description = "Name of the infrastructure CodePipeline"
  value       = var.deploy_cicd ? module.cicd[0].infra_pipeline_name : null
}

output "app_pipeline_name" {
  description = "Name of the application CodePipeline"
  value       = var.deploy_cicd ? module.cicd[0].app_pipeline_name : null
}

# ------------------------------------------------------------------------------
# Lambda Outputs
# ------------------------------------------------------------------------------

output "lambda_function_name" {
  description = "Name of the health monitor Lambda function"
  value       = var.deploy_lambda ? module.lambda[0].function_name : null
}
