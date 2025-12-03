resource "aws_sns_topic" "alerts" {
  name = "${var.env}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "ramagirijithendar1998@gmail.com"  # your email
}
