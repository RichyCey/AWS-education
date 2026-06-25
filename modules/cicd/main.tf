resource "aws_codestarconnections_connection" "github" {
  count         = var.codestar_connection_arn == "" ? 1 : 0
  name          = "${var.project_name}-github"
  provider_type = "GitHub"

  tags = {
    Name = "${var.project_name}-github-connection"
  }
}

locals {
  connection_arn = var.codestar_connection_arn != "" ? var.codestar_connection_arn : aws_codestarconnections_connection.github[0].arn
}

resource "aws_s3_bucket" "artifacts" {
  bucket_prefix = "${var.project_name}-pipeline-"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-pipeline-artifacts"
  }
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ------------------------------------------------------------------------------
# CodeBuild - Terraform Validate
# ------------------------------------------------------------------------------

resource "aws_codebuild_project" "tf_validate" {
  name         = "${var.project_name}-tf-validate"
  description  = "Terraform format check, validate, and plan"
  service_role = var.terraform_codebuild_role_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = false
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspecs/buildspec_validate.yml"
  }

  tags = {
    Name = "${var.project_name}-tf-validate"
  }
}

# ------------------------------------------------------------------------------
# CodeBuild - Terraform Deploy
# ------------------------------------------------------------------------------

resource "aws_codebuild_project" "tf_deploy" {
  name         = "${var.project_name}-tf-deploy"
  description  = "Terraform apply"
  service_role = var.terraform_codebuild_role_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = false
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspecs/buildspec_deploy.yml"
  }

  tags = {
    Name = "${var.project_name}-tf-deploy"
  }
}

# ------------------------------------------------------------------------------
# CodeBuild - App Build (Docker)
# ------------------------------------------------------------------------------

resource "aws_codebuild_project" "app_build" {
  name         = "${var.project_name}-app-build"
  description  = "Docker build, tag, and push to ECR"
  service_role = var.codebuild_role_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "ECR_REPO_URI"
      value = var.ecr_repository_url
    }

    environment_variable {
      name  = "TASK_DEF_FAMILY"
      value = var.task_definition_family
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspecs/buildspec_app.yml"
  }

  tags = {
    Name = "${var.project_name}-app-build"
  }
}

# ------------------------------------------------------------------------------
# CodeDeploy - ECS Blue/Green
# ------------------------------------------------------------------------------

resource "aws_codedeploy_app" "ecs" {
  compute_platform = "ECS"
  name             = "${var.project_name}-ecs-deploy"

  tags = {
    Name = "${var.project_name}-ecs-deploy"
  }
}

resource "aws_codedeploy_deployment_group" "ecs" {
  app_name               = aws_codedeploy_app.ecs.name
  deployment_group_name  = "${var.project_name}-ecs-dg"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = var.codedeploy_role_arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.ecs_service_name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.prod_listener_arn]
      }

      test_traffic_route {
        listener_arns = [var.test_listener_arn]
      }

      target_group {
        name = var.green_target_group_name
      }

      target_group {
        name = var.blue_target_group_name
      }
    }
  }

  tags = {
    Name = "${var.project_name}-ecs-deployment-group"
  }
}

# ------------------------------------------------------------------------------
# CodePipeline - Infrastructure
# ------------------------------------------------------------------------------

resource "aws_codepipeline" "infra" {
  name          = "${var.project_name}-infra-pipeline"
  role_arn      = var.codepipeline_role_arn
  pipeline_type = "V2"

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = local.connection_arn
        FullRepositoryId = "${var.github_owner}/${var.github_repo}"
        BranchName       = var.github_branch
        DetectChanges    = "true"
      }
    }
  }

  stage {
    name = "Validate"

    action {
      name             = "Terraform_Validate"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["validate_output"]

      configuration = {
        ProjectName = aws_codebuild_project.tf_validate.name
      }
    }
  }

  stage {
    name = "Approval"

    action {
      name     = "Manual_Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
        NotificationArn = var.sns_topic_arn
        CustomData      = "Review the Terraform plan output and approve to proceed with apply."
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Terraform_Apply"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_output"]

      configuration = {
        ProjectName = aws_codebuild_project.tf_deploy.name
      }
    }
  }

  tags = {
    Name = "${var.project_name}-infra-pipeline"
  }
}

# ------------------------------------------------------------------------------
# CodePipeline - Application
# ------------------------------------------------------------------------------

resource "aws_codepipeline" "app" {
  name          = "${var.project_name}-app-pipeline"
  role_arn      = var.codepipeline_role_arn
  pipeline_type = "V2"

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = local.connection_arn
        FullRepositoryId = "${var.github_owner}/${var.github_repo}"
        BranchName       = var.github_branch
        DetectChanges    = "true"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Docker_Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.app_build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "ECS_BlueGreen"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ApplicationName                = aws_codedeploy_app.ecs.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.ecs.deployment_group_name
        TaskDefinitionTemplateArtifact = "build_output"
        TaskDefinitionTemplatePath     = "taskdef.json"
        AppSpecTemplateArtifact        = "build_output"
        AppSpecTemplatePath            = "appspec.yaml"
        Image1ArtifactName             = "build_output"
        Image1ContainerName            = "IMAGE1_NAME"
      }
    }
  }

  tags = {
    Name = "${var.project_name}-app-pipeline"
  }
}
