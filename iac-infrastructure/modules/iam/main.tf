locals {
  attachments_arn = "arn:aws:s3:::${var.attachments_bucket}"
  deploy_arn      = "arn:aws:s3:::${var.deploy_bucket}"
  secret_arn      = "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:${var.app_secret}-*"
}

data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "app_access" {
  statement {
    sid       = "BucketsList"
    actions   = ["s3:ListBucket"]
    resources = [local.attachments_arn, local.deploy_arn]
  }
  statement {
    sid       = "AttachmentsObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${local.attachments_arn}/*"]
  }
  statement {
    sid       = "DeployObjectsReadOnly"
    actions   = ["s3:GetObject"]
    resources = ["${local.deploy_arn}/*"]
  }
  statement {
    sid       = "AppSecret"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [local.secret_arn]
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${var.project}-app-ec2"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

resource "aws_iam_role_policy" "ec2" {
  name   = "s3-and-secret"
  role   = aws_iam_role.ec2.id
  policy = data.aws_iam_policy_document.app_access.json
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project}-app-ec2"
  role = aws_iam_role.ec2.name
}