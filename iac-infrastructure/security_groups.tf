module "security_groups" {
  source                = "./modules/security_groups"
  project               = var.project
  region                = var.region
  vpc_id                = module.network.vpc_id
  allow_internet_egress = var.enable_nat
}