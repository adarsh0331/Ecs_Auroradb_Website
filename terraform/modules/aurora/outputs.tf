output "db_cluster_id" {
  description = "The ID of the Aurora cluster"
  value       = aws_rds_cluster.aurora_cluster.id
}

output "db_password" {
  value     = random_password.db_password.result
  sensitive = true
}

output "aurora_endpoint" {
  description = "The writer endpoint of the Aurora cluster"
  value       = aws_rds_cluster.aurora_cluster.endpoint
}

output "aurora_reader_endpoint" {
  description = "The reader endpoint of the Aurora cluster"
  value       = aws_rds_cluster.aurora_cluster.reader_endpoint
}

output "aurora_cluster_arn" {
  description = "The ARN of the Aurora cluster"
  value       = aws_rds_cluster.aurora_cluster.arn
}
