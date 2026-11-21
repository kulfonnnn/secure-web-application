data "aws_region" "primary" {}

data "aws_region" "global" {
  provider = aws.us_east_1
}

module "network" {
  source   = "./modules/network"
  project  = var.project
  vpc_cidr = var.vpc_cidr

  subnets = {
    public-a = { cidr = "10.0.1.0/24", az = "a", tier = "public" }
    app-a    = { cidr = "10.0.2.0/24", az = "a", tier = "app" }
    data-a   = { cidr = "10.0.3.0/24", az = "a", tier = "data" }
    public-b = { cidr = "10.0.11.0/24", az = "b", tier = "public" }
    app-b    = { cidr = "10.0.12.0/24", az = "b", tier = "app" }
    data-b   = { cidr = "10.0.13.0/24", az = "b", tier = "data" }
  }
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  names = {
    state_bucket       = "${var.project}-tfstate-${local.account_id}"
    attachments_bucket = "${var.project}-attachments-${local.account_id}"
    deploy_bucket      = "${var.project}-deploy-${local.account_id}"
    alb_logs_bucket    = "${var.project}-alb-logs-${local.account_id}"
    app_secret         = "${var.project}/app"
  }
}

module "iam" {
  source             = "./modules/iam"
  project            = var.project
  region             = var.region
  account_id         = local.account_id
  attachments_bucket = local.names.attachments_bucket
  deploy_bucket      = local.names.deploy_bucket
  app_secret         = local.names.app_secret
}