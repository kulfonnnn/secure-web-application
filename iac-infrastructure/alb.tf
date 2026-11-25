resource "random_password" "origin_verify" {
  length  = 40
  special = false
}

module "alb" {
  count                = var.enable_alb ? 1 : 0
  source               = "./modules/alb"
  project              = var.project
  vpc_id               = module.network.vpc_id
  subnet_ids           = module.network.subnet_ids_by_tier["public"]
  security_group_id    = module.security_groups.ids["alb"]
  logs_bucket          = module.alb_logs.bucket_name
  instance_ids         = module.ec2.instance_ids
  certificate_arn      = aws_acm_certificate_validation.alb.certificate_arn
  origin_verify_secret = random_password.origin_verify.result

  # Polityka bucketa logów musi istnieć przed utworzeniem ALB
  depends_on = [module.alb_logs]
}

moved {
  from = module.alb
  to   = module.alb[0]
}