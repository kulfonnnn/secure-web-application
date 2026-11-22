module "secrets" {
  source                     = "./modules/secrets"
  project                    = var.project
  region                     = var.region
  secret_name                = local.names.app_secret
  vpc_id                     = module.network.vpc_id
  endpoint_subnet_id         = module.network.subnet_ids["app-a"]
  endpoint_security_group_id = module.security_groups.ids["secrets"]
}