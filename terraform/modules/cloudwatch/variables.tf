variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "env" {
  description = "Environment name (dev/staging)"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS Cluster name"
  type        = string
}

variable "db_cluster_id" {
  description = "Aurora DB Cluster Identifier"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic for sending alerts"
  type        = string
}
