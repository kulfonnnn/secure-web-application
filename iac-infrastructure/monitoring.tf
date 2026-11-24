module "monitoring" {
  source                  = "./modules/monitoring"
  project                 = var.project
  region                  = var.region
  alert_email             = var.alert_email
  instance_ids            = module.ec2.instance_ids
  db_instance_id          = module.rds.instance_id
  alb_arn_suffix          = module.alb.arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  cache_cluster_id        = module.cache.member_cluster_id
}