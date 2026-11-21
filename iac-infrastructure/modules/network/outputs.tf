output "vpc_id" {
  value = aws_vpc.this.id
}

output "subnet_ids" {
  description = "Identyfikatory podsieci wg nazwy"
  value       = { for k, s in aws_subnet.this : k => s.id }
}

output "subnet_ids_by_tier" {
  description = "Identyfikatory podsieci wg warstwy"
  value = {
    for t in local.tiers : t => [for k, s in var.subnets : aws_subnet.this[k].id if s.tier == t]
  }
}

output "route_table_ids" {
  value = { for t, rt in aws_route_table.this : t => rt.id }
}