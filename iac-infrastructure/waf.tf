resource "aws_wafv2_web_acl" "this" {
  count       = var.enable_waf ? 1 : 0
  provider    = aws.us_east_1
  name        = "${var.project}-web-acl"
  description = "Ochrona aplikacji za CloudFront"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "aws-common"
    priority = 10

    override_action {
      dynamic "none" {
        for_each = var.waf_block ? [1] : []
        content {}
      }
      dynamic "count" {
        for_each = var.waf_block ? [] : [1]
        content {}
      }
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          name = "SizeRestrictions_BODY"
          action_to_use {
            count {}
          }
        }
        rule_action_override {
          name = "CrossSiteScripting_BODY"
          action_to_use {
            count {}
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-common"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "aws-bad-inputs"
    priority = 20

    override_action {
      dynamic "none" {
        for_each = var.waf_block ? [1] : []
        content {}
      }
      dynamic "count" {
        for_each = var.waf_block ? [] : [1]
        content {}
      }
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "aws-ip-reputation"
    priority = 30

    override_action {
      dynamic "none" {
        for_each = var.waf_block ? [1] : []
        content {}
      }
      dynamic "count" {
        for_each = var.waf_block ? [] : [1]
        content {}
      }
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-ip-reputation"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "login-rate-limit"
    priority = 40

    action {
      dynamic "block" {
        for_each = var.waf_block ? [1] : []
        content {}
      }
      dynamic "count" {
        for_each = var.waf_block ? [] : [1]
        content {}
      }
    }

    statement {
      rate_based_statement {
        limit                 = var.rate_limit
        aggregate_key_type    = "IP"
        evaluation_window_sec = 300

        scope_down_statement {
          or_statement {
            dynamic "statement" {
              for_each = var.rate_limited_paths
              content {
                byte_match_statement {
                  search_string         = statement.value
                  positional_constraint = "STARTS_WITH"
                  field_to_match {
                    uri_path {}
                  }
                  text_transformation {
                    priority = 0
                    type     = "NONE"
                  }
                }
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "login-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project}-web-acl"
    sampled_requests_enabled   = true
  }
}

resource "aws_cloudwatch_log_group" "waf" {
  provider          = aws.us_east_1
  name              = "aws-waf-logs-${var.project}"
  retention_in_days = 14
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count                   = var.enable_waf ? 1 : 0
  provider                = aws.us_east_1
  resource_arn            = aws_wafv2_web_acl.this[0].arn
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]

  redacted_fields {
    single_header {
      name = "cookie"
    }
  }
  redacted_fields {
    single_header {
      name = "authorization"
    }
  }
}

moved {
  from = aws_wafv2_web_acl.this
  to   = aws_wafv2_web_acl.this[0]
}

moved {
  from = aws_wafv2_web_acl_logging_configuration.this
  to   = aws_wafv2_web_acl_logging_configuration.this[0]
}