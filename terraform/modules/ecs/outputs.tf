output "alb_dns_name" {
  value = aws_lb.ecs_alb.dns_name
}

output "alb_zone_id" {
  value = aws_lb.ecs_alb.zone_id
}

output "ecs_sg_id" {
  value = aws_security_group.ecs_sg.id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}
