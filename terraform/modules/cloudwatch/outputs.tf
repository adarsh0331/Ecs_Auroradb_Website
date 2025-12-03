output "log_group_name" {
  description = "ECS Log Group Name"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "dashboard_name" {
  description = "CloudWatch Dashboard Name"
  value       = aws_cloudwatch_dashboard.ecs_aurora_dashboard.dashboard_name
}
output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = var.ecs_cluster_name
}