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