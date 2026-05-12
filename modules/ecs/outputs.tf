output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_arn" {
  value = aws_lb.main.arn
}

output "alb_arn_suffix" {
  value = aws_lb.main.arn_suffix
}

output "target_group_arn_suffix" {
  value = aws_lb_target_group.openwebui.arn_suffix
}

output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "service_name" {
  value = aws_ecs_service.app.name
}

output "task_definition_family" {
  value = aws_ecs_task_definition.app.family
}

output "prod_listener_arn" {
  value = aws_lb_listener.http.arn
}

output "test_listener_arn" {
  value = aws_lb_listener.test.arn
}

output "blue_target_group_name" {
  value = aws_lb_target_group.openwebui.name
}

output "green_target_group_name" {
  value = aws_lb_target_group.openwebui_green.name
}
