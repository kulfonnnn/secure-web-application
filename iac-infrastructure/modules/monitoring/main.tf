data "aws_caller_identity" "current" {}

# --- SNS ---
resource "aws_sns_topic" "alerts" {
  name = "${var.project}-alerts"
}

data "aws_iam_policy_document" "alerts" {
  statement {
    sid       = "CloudWatchAlarms"
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.alerts.arn]
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
  statement {
    sid       = "EventBridge"
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.alerts.arn]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_sns_topic_policy" "alerts" {
  arn    = aws_sns_topic.alerts.arn
  policy = data.aws_iam_policy_document.alerts.json
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# --- Definicje alarmów ---
locals {
  alb   = coalesce(var.alb_arn_suffix, "disabled")
  tg    = coalesce(var.target_group_arn_suffix, "disabled")
  cache = coalesce(var.cache_cluster_id, "disabled")
  ec2_alarms = merge([
    for k, id in var.instance_ids : {
      "ec2-${k}-cpu" = {
        namespace          = "AWS/EC2"
        metric             = "CPUUtilization"
        dimensions         = { InstanceId = id }
        statistic          = "Average"
        period             = 300
        evaluation_periods = 2
        threshold          = 80
        comparison         = "GreaterThanThreshold"
        description        = "CPU instancji ${k} powyżej 80% przez 10 minut"
      }
      "ec2-${k}-status" = {
        namespace          = "AWS/EC2"
        metric             = "StatusCheckFailed"
        dimensions         = { InstanceId = id }
        statistic          = "Maximum"
        period             = 60
        evaluation_periods = 2
        threshold          = 0
        comparison         = "GreaterThanThreshold"
        description        = "Niepowodzenie kontroli stanu instancji ${k}"
      }
    }
  ]...)

  alb_alarms_all = {
    "alb-unhealthy" = {
      namespace          = "AWS/ApplicationELB"
      metric             = "UnHealthyHostCount"
      dimensions         = { LoadBalancer = local.alb, TargetGroup = local.tg }
      statistic          = "Maximum"
      period             = 60
      evaluation_periods = 2
      threshold          = 0
      comparison         = "GreaterThanThreshold"
      description        = "Niezdrowe cele w Target Group"
    }
    "alb-app-5xx" = {
      namespace          = "AWS/ApplicationELB"
      metric             = "HTTPCode_Target_5XX_Count"
      dimensions         = { LoadBalancer = local.alb }
      statistic          = "Sum"
      period             = 300
      evaluation_periods = 1
      threshold          = 5
      comparison         = "GreaterThanThreshold"
      description        = "Błędy aplikacji: ponad 5 odpowiedzi 5xx z instancji w 5 minut"
    }
    "alb-elb-5xx" = {
      namespace          = "AWS/ApplicationELB"
      metric             = "HTTPCode_ELB_5XX_Count"
      dimensions         = { LoadBalancer = local.alb }
      statistic          = "Sum"
      period             = 300
      evaluation_periods = 1
      threshold          = 5
      comparison         = "GreaterThanThreshold"
      description        = "Błędy 5xx zwracane przez sam ALB"
    }
    "alb-latency" = {
      namespace          = "AWS/ApplicationELB"
      metric             = "TargetResponseTime"
      dimensions         = { LoadBalancer = local.alb }
      statistic          = "Average"
      period             = 300
      evaluation_periods = 2
      threshold          = 2
      comparison         = "GreaterThanThreshold"
      description        = "Średni czas odpowiedzi powyżej 2 s"
    }
  }

  rds_alarms = {
    "rds-cpu" = {
      namespace          = "AWS/RDS"
      metric             = "CPUUtilization"
      dimensions         = { DBInstanceIdentifier = var.db_instance_id }
      statistic          = "Average"
      period             = 300
      evaluation_periods = 2
      threshold          = 80
      comparison         = "GreaterThanThreshold"
      description        = "CPU bazy powyżej 80% przez 10 minut"
    }
    "rds-storage" = {
      namespace          = "AWS/RDS"
      metric             = "FreeStorageSpace"
      dimensions         = { DBInstanceIdentifier = var.db_instance_id }
      statistic          = "Minimum"
      period             = 300
      evaluation_periods = 1
      threshold          = 2147483648
      comparison         = "LessThanThreshold"
      description        = "Mniej niż 2 GiB wolnego miejsca w bazie"
    }
    "rds-connections" = {
      namespace          = "AWS/RDS"
      metric             = "DatabaseConnections"
      dimensions         = { DBInstanceIdentifier = var.db_instance_id }
      statistic          = "Maximum"
      period             = 300
      evaluation_periods = 1
      threshold          = 60
      comparison         = "GreaterThanThreshold"
      description        = "Ponad 60 połączeń z bazą"
    }
  }

  cache_alarms_all = {
    "cache-cpu" = {
      namespace          = "AWS/ElastiCache"
      metric             = "EngineCPUUtilization"
      dimensions         = { CacheClusterId = local.cache }
      statistic          = "Average"
      period             = 300
      evaluation_periods = 2
      threshold          = 80
      comparison         = "GreaterThanThreshold"
      description        = "CPU silnika Valkey powyżej 80% przez 10 minut"
    }
    "cache-memory" = {
      namespace          = "AWS/ElastiCache"
      metric             = "DatabaseMemoryUsagePercentage"
      dimensions         = { CacheClusterId = local.cache }
      statistic          = "Average"
      period             = 300
      evaluation_periods = 1
      threshold          = 80
      comparison         = "GreaterThanThreshold"
      description        = "Pamięć Valkey zajęta w ponad 80%"
    }
  }
  alb_alarms   = { for k, v in local.alb_alarms_all : k => v if var.alb_arn_suffix != null }
  cache_alarms = { for k, v in local.cache_alarms_all : k => v if var.cache_cluster_id != null }
  all_alarms   = merge(local.ec2_alarms, local.alb_alarms_all, local.rds_alarms, local.cache_alarms_all)
}

resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = local.all_alarms

  alarm_name          = "${var.project}-${each.key}"
  alarm_description   = each.value.description
  namespace           = each.value.namespace
  metric_name         = each.value.metric
  dimensions          = each.value.dimensions
  statistic           = each.value.statistic
  period              = each.value.period
  evaluation_periods  = each.value.evaluation_periods
  threshold           = each.value.threshold
  comparison_operator = each.value.comparison
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

# --- EventBridge ---
resource "aws_cloudwatch_event_rule" "ec2_state" {
  name = "${var.project}-ec2-state"
  event_pattern = jsonencode({
    source        = ["aws.ec2"]
    "detail-type" = ["EC2 Instance State-change Notification"]
    detail = {
      state         = ["stopped", "terminated"]
      "instance-id" = values(var.instance_ids)
    }
  })
}

resource "aws_cloudwatch_event_target" "ec2_state" {
  rule = aws_cloudwatch_event_rule.ec2_state.name
  arn  = aws_sns_topic.alerts.arn

  input_transformer {
    input_paths = {
      id    = "$.detail.instance-id"
      state = "$.detail.state"
    }
    input_template = "\"Instancja <id> zmienila stan na <state>\""
  }
}

resource "aws_cloudwatch_event_rule" "health" {
  name          = "${var.project}-aws-health"
  event_pattern = jsonencode({ source = ["aws.health"] })
}

resource "aws_cloudwatch_event_target" "health" {
  rule = aws_cloudwatch_event_rule.health.name
  arn  = aws_sns_topic.alerts.arn
}

# --- Dashboard ---
resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.project}-overview"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title   = "EC2: CPU [%]", region = var.region, stat = "Average", period = 300, view = "timeSeries"
          metrics = [for k, id in var.instance_ids : ["AWS/EC2", "CPUUtilization", "InstanceId", id, { label = "EC2 ${k}" }]]
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title = "ALB: liczba żądań i błędy", region = var.region, stat = "Sum", period = 300, view = "timeSeries"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.alb, { label = "Żądania" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", local.alb, { label = "5xx aplikacji" }],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", local.alb, { label = "5xx ALB" }],
          ]
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title   = "ALB: czas odpowiedzi [s]", region = var.region, stat = "Average", period = 300, view = "timeSeries"
          metrics = [["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", local.alb]]
        }
      },
      {
        type = "metric", x = 12, y = 6, width = 12, height = 6
        properties = {
          title = "RDS: CPU [%] i połączenia", region = var.region, stat = "Average", period = 300, view = "timeSeries"
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.db_instance_id, { label = "CPU" }],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.db_instance_id, { label = "Połączenia" }],
          ]
        }
      },
      {
        type = "metric", x = 0, y = 12, width = 12, height = 6
        properties = {
          title = "ElastiCache: CPU [%] i pamięć [%]", region = var.region, stat = "Average", period = 300, view = "timeSeries"
          metrics = [
            ["AWS/ElastiCache", "EngineCPUUtilization", "CacheClusterId", local.cache, { label = "CPU" }],
            ["AWS/ElastiCache", "DatabaseMemoryUsagePercentage", "CacheClusterId", local.cache, { label = "Pamięć" }],
          ]
        }
      },
    ]
  })
}