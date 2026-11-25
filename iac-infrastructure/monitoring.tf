module "monitoring" {
  source                  = "./modules/monitoring"
  project                 = var.project
  region                  = var.region
  alert_email             = var.alert_email
  instance_ids            = module.ec2.instance_ids
  db_instance_id          = module.rds.instance_id
  alb_arn_suffix          = try(module.alb[0].arn_suffix, null)
  target_group_arn_suffix = try(module.alb[0].target_group_arn_suffix, null)
  cache_cluster_id        = try(module.cache[0].member_cluster_id, null)
}