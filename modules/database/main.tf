resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_data_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "-_"
}

resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-db"

  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  multi_az               = var.enable_multi_az
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_sg_id]

  backup_retention_period = 1
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  skip_final_snapshot = true
  deletion_protection = false

  performance_insights_enabled = false

  tags = {
    Name = "${var.project_name}-db"
  }
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "prod/database/credentials"
  description             = "RDS PostgreSQL database credentials"
  recovery_window_in_days = 0

  tags = {
    Name = "prod-database-credentials"
  }
}

resource "aws_secretsmanager_secret_policy" "db_credentials" {
  secret_arn = aws_secretsmanager_secret.db_credentials.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowECSTaskExecutionRole"
        Effect = "Allow"
        Principal = {
          AWS = var.ecs_task_execution_role_arn
        }
        Action   = "secretsmanager:GetSecretValue"
        Resource = aws_secretsmanager_secret.db_credentials.arn
      },
      {
        Sid    = "AllowCodeBuildRole"
        Effect = "Allow"
        Principal = {
          AWS = var.codebuild_role_arn
        }
        Action   = "secretsmanager:GetSecretValue"
        Resource = aws_secretsmanager_secret.db_credentials.arn
      }
    ]
  })
}

resource "random_password" "webui_secret_key" {
  length  = 48
  special = false
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    username         = var.db_username
    password         = random_password.db_password.result
    engine           = "postgres"
    host             = aws_db_instance.main.address
    port             = aws_db_instance.main.port
    dbname           = var.db_name
    endpoint         = aws_db_instance.main.endpoint
    database_url     = "postgresql://${var.db_username}:${random_password.db_password.result}@${aws_db_instance.main.address}:${aws_db_instance.main.port}/${var.db_name}"
    webui_secret_key = random_password.webui_secret_key.result
  })
}
