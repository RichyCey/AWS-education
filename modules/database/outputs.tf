output "rds_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "rds_address" {
  value = aws_db_instance.main.address
}

output "rds_resource_id" {
  value = aws_db_instance.main.resource_id
}

output "db_credentials_secret_arn" {
  value = aws_secretsmanager_secret.db_credentials.arn
}

output "rds_instance_identifier" {
  value = aws_db_instance.main.identifier
}
