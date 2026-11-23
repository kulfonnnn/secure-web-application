module "rds" {
  source            = "./modules/rds"
  project           = var.project
  subnet_ids        = module.network.subnet_ids_by_tier["data"]
  security_group_id = module.security_groups.ids["rds"]
  password          = module.secrets.db_password
  availability_zone = "${var.region}a"
}