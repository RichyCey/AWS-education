module "networking" {
  source = "./modules/networking"

  project_name              = var.project_name
  vpc_cidr                  = var.vpc_cidr
  availability_zones        = var.availability_zones
  public_subnet_cidrs       = var.public_subnet_cidrs
  private_app_subnet_cidrs  = var.private_app_subnet_cidrs
  private_data_subnet_cidrs = var.private_data_subnet_cidrs
}

module "security" {
  source = "./modules/security"

  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
}

module "iam" {
  source = "./modules/iam"

  project_name              = var.project_name
  aws_region                = var.aws_region
  db_credentials_secret_arn = module.database.db_credentials_secret_arn
  rds_resource_id           = module.database.rds_resource_id
  db_username               = var.db_username
}

module "database" {
  source = "./modules/database"

  project_name                = var.project_name
  private_data_subnet_ids     = module.networking.private_data_subnet_ids
  rds_sg_id                   = module.security.rds_sg_id
  db_engine_version           = var.db_engine_version
  db_name                     = var.db_name
  db_username                 = var.db_username
  enable_multi_az             = var.enable_multi_az
  ecs_task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  codebuild_role_arn          = module.iam.codebuild_role_arn
}

module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
}

module "ecs" {
  source = "./modules/ecs"

  project_name                = var.project_name
  aws_region                  = var.aws_region
  vpc_id                      = module.networking.vpc_id
  public_subnet_ids           = module.networking.public_subnet_ids
  private_app_subnet_ids      = module.networking.private_app_subnet_ids
  alb_sg_id                   = module.security.alb_sg_id
  app_sg_id                   = module.security.app_sg_id
  ecs_task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  ecs_task_role_arn           = module.iam.ecs_task_role_arn
  db_credentials_secret_arn   = module.database.db_credentials_secret_arn
  ecr_repository_url          = module.ecr.repository_url
  ollama_image_tag            = var.ollama_image_tag
  ecs_desired_count           = var.ecs_desired_count
  ecs_max_count               = var.ecs_max_count
}

module "monitoring" {
  source = "./modules/monitoring"

  project_name            = var.project_name
  ecs_cluster_name        = module.ecs.cluster_name
  ecs_service_name        = module.ecs.service_name
  ecs_desired_count       = var.ecs_desired_count
  alb_arn_suffix          = module.ecs.alb_arn_suffix
  target_group_arn_suffix = module.ecs.target_group_arn_suffix
  rds_instance_identifier = module.database.rds_instance_identifier
  alert_email             = var.alert_email
}

module "cicd" {
  source = "./modules/cicd"
  count  = var.deploy_cicd ? 1 : 0

  project_name                 = var.project_name
  aws_region                   = var.aws_region
  codestar_connection_arn      = var.codestar_connection_arn
  github_owner                 = var.github_owner
  github_repo                  = var.github_repo
  github_branch                = var.github_branch
  codebuild_role_arn           = module.iam.codebuild_role_arn
  terraform_codebuild_role_arn = module.iam.terraform_codebuild_role_arn
  codepipeline_role_arn        = module.iam.codepipeline_role_arn
  codedeploy_role_arn          = module.iam.codedeploy_role_arn
  ecr_repository_url           = module.ecr.repository_url
  task_definition_family       = module.ecs.task_definition_family
  ecs_cluster_name             = module.ecs.cluster_name
  ecs_service_name             = module.ecs.service_name
  prod_listener_arn            = module.ecs.prod_listener_arn
  test_listener_arn            = module.ecs.test_listener_arn
  blue_target_group_name       = module.ecs.blue_target_group_name
  green_target_group_name      = module.ecs.green_target_group_name
  sns_topic_arn                = module.monitoring.sns_topic_arn
}

module "lambda" {
  source = "./modules/lambda"
  count  = var.deploy_lambda ? 1 : 0

  project_name              = var.project_name
  aws_region                = var.aws_region
  private_app_subnet_ids    = module.networking.private_app_subnet_ids
  lambda_sg_id              = module.security.lambda_sg_id
  alb_dns_name              = module.ecs.alb_dns_name
  db_credentials_secret_arn = module.database.db_credentials_secret_arn
}


# Test