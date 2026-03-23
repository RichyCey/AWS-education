resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "prod/database/credentials"
  description             = "RDS PostgreSQL database credentials"
  recovery_window_in_days = 0

  tags = {
    Name = "prod-database-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    engine   = "postgres"
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    dbname   = var.db_name
    endpoint = aws_db_instance.main.endpoint
  })
}
