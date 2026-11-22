output "ids" {
  description = "Identyfikatory grup bezpieczeństwa wg krótkiej nazwy"
  value       = { for k, sg in aws_security_group.this : k => sg.id }
}