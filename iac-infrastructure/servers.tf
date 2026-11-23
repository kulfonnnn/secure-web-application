module "ec2" {
  source                = "./modules/ec2"
  project               = var.project
  region                = var.region
  app_subnet_ids        = { a = module.network.subnet_ids["app-a"], b = module.network.subnet_ids["app-b"] }
  security_group_id     = module.security_groups.ids["ec2"]
  eic_security_group_id = module.security_groups.ids["eic"]
  instance_profile_name = module.iam.ec2_instance_profile_name
  deploy_bucket         = module.deploy.bucket_name

  # Najpierw sieć (w tym NAT i trasa), reguły SG oraz pliki w S3
  depends_on = [module.network, module.security_groups, aws_s3_object.app_config, aws_s3_object.release]
}