output "function_name" {
  value = aws_lambda_function.health_monitor.function_name
}

output "function_arn" {
  value = aws_lambda_function.health_monitor.arn
}

output "eventbridge_rule_name" {
  value = aws_cloudwatch_event_rule.health_check.name
}
