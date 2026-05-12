# ------------------------------------------------------------------------------
# IAM Role for Lambda
# ------------------------------------------------------------------------------

resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-health-monitor-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-health-monitor-role"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "lambda" {
  name = "${var.project_name}-health-monitor-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = var.db_credentials_secret_arn
      },
      {
        Effect   = "Allow"
        Action   = ["cloudwatch:PutMetricData"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["elasticloadbalancing:DescribeTargetHealth"]
        Resource = "*"
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# Lambda Layer (psycopg2)
# ------------------------------------------------------------------------------

resource "aws_lambda_layer_version" "psycopg2" {
  filename            = "${path.root}/lambda/psycopg2_layer.zip"
  layer_name          = "${var.project_name}-psycopg2"
  compatible_runtimes = ["python3.13"]
  description         = "psycopg2-binary for PostgreSQL access"
  source_code_hash    = fileexists("${path.root}/lambda/psycopg2_layer.zip") ? filebase64sha256("${path.root}/lambda/psycopg2_layer.zip") : null
}

# ------------------------------------------------------------------------------
# Lambda Function
# ------------------------------------------------------------------------------

data "archive_file" "health_monitor" {
  type        = "zip"
  source_file = "${path.root}/lambda/health_monitor.py"
  output_path = "${path.root}/lambda/health_monitor.zip"
}

resource "aws_lambda_function" "health_monitor" {
  filename         = data.archive_file.health_monitor.output_path
  function_name    = "${var.project_name}-health-monitor"
  role             = aws_iam_role.lambda.arn
  handler          = "health_monitor.handler"
  runtime          = "python3.13"
  timeout          = 60
  memory_size      = 128
  source_code_hash = data.archive_file.health_monitor.output_base64sha256

  layers = [aws_lambda_layer_version.psycopg2.arn]

  vpc_config {
    subnet_ids         = var.private_app_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }

  environment {
    variables = {
      ALB_DNS_NAME  = var.alb_dns_name
      DB_SECRET_ARN = var.db_credentials_secret_arn
      PROJECT_NAME  = var.project_name
    }
  }

  tags = {
    Name = "${var.project_name}-health-monitor"
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-health-monitor"
  retention_in_days = 30
}

# ------------------------------------------------------------------------------
# EventBridge - Trigger every 15 minutes
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "health_check" {
  name                = "${var.project_name}-health-check"
  description         = "Trigger health monitor Lambda every 15 minutes"
  schedule_expression = "rate(15 minutes)"

  tags = {
    Name = "${var.project_name}-health-check-rule"
  }
}

resource "aws_cloudwatch_event_target" "health_check" {
  rule      = aws_cloudwatch_event_rule.health_check.name
  target_id = "health-monitor"
  arn       = aws_lambda_function.health_monitor.arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health_monitor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.health_check.arn
}
