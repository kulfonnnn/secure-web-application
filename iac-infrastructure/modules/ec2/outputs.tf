output "instance_ids" {
  value = { for k, i in aws_instance.app : k => i.id }
}

output "private_ips" {
  value = { for k, i in aws_instance.app : k => i.private_ip }
}