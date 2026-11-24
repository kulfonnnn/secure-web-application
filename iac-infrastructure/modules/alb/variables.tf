variable "project" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  description = "Podsieci publiczne z dwóch stref"
  type        = list(string)
}

variable "security_group_id" {
  type = string
}

variable "logs_bucket" {
  type = string
}

variable "instance_ids" {
  description = "Instancje wg litery strefy"
  type        = map(string)
}

variable "certificate_arn" {
  description = "Certyfikat ACM dla listenera HTTPS"
  type        = string
}

variable "origin_verify_secret" {
  type      = string
  sensitive = true
}