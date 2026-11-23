variable "project" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "availability_zone" {
  description = "Strefa, w której działa węzeł"
  type        = string
}

variable "auth_token" {
  description = "Token AUTH (hasło) z Secrets Managera"
  type        = string
  sensitive   = true
}