output "regions" {
  value = {
    primary = data.aws_region.primary.region
    global  = data.aws_region.global.region
  }
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "subnet_ids" {
  value = module.network.subnet_ids
}


output "ec2_instance_profile" {
  value = module.iam.ec2_instance_profile_name
}

output "security_group_ids" {
  value = module.security_groups.ids
}

output "bucket_names" {
  value = {
    attachments = module.attachments.bucket_name
    deploy      = module.deploy.bucket_name
    alb_logs    = module.alb_logs.bucket_name
  }
}

output "db_endpoint" {
  value = module.rds.endpoint
}

output "cache_endpoint" {
  value = try(module.cache[0].endpoint, null)
}

output "instance_ids" {
  value = module.ec2.instance_ids
}

output "dns_validation_records" {
  value = [for r in aws_route53_record.cert_validation : r.fqdn]
}
output "alb_dns_name" {
  value = try(module.alb[0].dns_name, null)
}

output "app_url" {
  value = "https://${local.app_fqdn}"
}