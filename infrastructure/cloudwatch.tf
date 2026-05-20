# =========================
# SNS for email alerts
# =========================
resource "aws_sns_topic" "alerts" {
  name = "grocerymate-alerts"
}

resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# =========================
# EC2 Alarm - High CPU
# =========================
resource "aws_cloudwatch_metric_alarm" "ec2_high_cpu" {
  alarm_name          = "grocerymate-ec2-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Alarm when EC2 CPU exceeds 70%"
  dimensions = {
    InstanceId = aws_instance.app_server.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# =========================
# EC2 Alarm - Status Check
# =========================
resource "aws_cloudwatch_metric_alarm" "ec2_status_check" {
  alarm_name          = "grocerymate-ec2-status-check-failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "Alarm when EC2 instance status check fails"
  dimensions = {
    InstanceId = aws_instance.app_server.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# =========================
# RDS Alarm - High CPU
# Optional but useful
# =========================
resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name          = "grocerymate-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Alarm when RDS CPU exceeds 70%"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres_db.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}