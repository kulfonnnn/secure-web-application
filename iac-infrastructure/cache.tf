module "cache" {
  source            = "./modules/cache"
  project           = var.project
  subnet_ids        = module.network.subnet_ids_by_tier["data"]
  security_group_id = module.security_groups.ids["valkey"]
  availability_zone = "${var.region}a"
  auth_token        = module.secrets.redis_password
}