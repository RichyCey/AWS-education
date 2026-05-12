output "codestar_connection_arn" {
  value = local.connection_arn
}

output "infra_pipeline_name" {
  value = aws_codepipeline.infra.name
}

output "app_pipeline_name" {
  value = aws_codepipeline.app.name
}

output "artifact_bucket_name" {
  value = aws_s3_bucket.artifacts.bucket
}

output "codedeploy_app_name" {
  value = aws_codedeploy_app.ecs.name
}

output "codedeploy_deployment_group_name" {
  value = aws_codedeploy_deployment_group.ecs.deployment_group_name
}
