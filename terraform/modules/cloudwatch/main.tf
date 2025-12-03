############################################
# CloudWatch Log Group for ECS
############################################
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.env}-application"
  retention_in_days = 30
}

############################################
# ECS CPU Utilization Alarm
############################################
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.env}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm when ECS CPU exceeds 80%"
  dimensions = {
    ClusterName = var.ecs_cluster_name
  }
  alarm_actions = [var.sns_topic_arn]
}

############################################
# ECS Memory Utilization Alarm
############################################
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "${var.env}-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm when ECS Memory exceeds 80%"
  dimensions = {
    ClusterName = var.ecs_cluster_name
  }
  alarm_actions = [var.sns_topic_arn]
}

############################################
# Aurora DB CPU Utilization Alarm
############################################
resource "aws_cloudwatch_metric_alarm" "aurora_cpu_high" {
  alarm_name          = "${var.env}-aurora-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm when Aurora CPU exceeds 80%"
  dimensions = {
    DBClusterIdentifier = var.db_cluster_id
  }
  alarm_actions = [var.sns_topic_arn]
}

############################################
# CloudWatch Dashboard (Fixed)
############################################
resource "aws_cloudwatch_dashboard" "ecs_aurora_dashboard" {
  dashboard_name = "${var.env}-monitoring-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x = 0,
        y = 0,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", var.ecs_cluster_name]
          ],
          region = var.aws_region,
          view   = "timeSeries",
          stat   = "Average",
          period = 60,
          title  = "ECS CPU & Memory Utilization"
        }
      },
      {
        type = "metric",
        x = 0,
        y = 7,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBClusterIdentifier", var.db_cluster_id],
            ["AWS/RDS", "FreeStorageSpace", "DBClusterIdentifier", var.db_cluster_id]
          ],
          region = var.aws_region,
          view   = "timeSeries",
          stat   = "Average",
          period = 300,
          title  = "Aurora DB Health Metrics"
        }
      }
    ]
  })
}
