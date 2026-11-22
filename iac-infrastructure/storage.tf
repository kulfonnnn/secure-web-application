data "aws_elb_service_account" "main" {}

data "aws_iam_policy_document" "alb_logs_delivery" {
  statement {
    sid       = "AlbLogDelivery"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${local.names.alb_logs_bucket}/AWSLogs/${local.account_id}/*"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.main.arn]
    }
  }
}

module "attachments" {
  source                     = "./modules/s3_bucket"
  bucket_name                = local.names.attachments_bucket
  versioning                 = true
  noncurrent_expiration_days = 30
}

module "deploy" {
  source        = "./modules/s3_bucket"
  bucket_name   = local.names.deploy_bucket
  force_destroy = true
}

module "alb_logs" {
  source            = "./modules/s3_bucket"
  bucket_name       = local.names.alb_logs_bucket
  expiration_days   = 30
  force_destroy     = true
  extra_policy_json = data.aws_iam_policy_document.alb_logs_delivery.json
}