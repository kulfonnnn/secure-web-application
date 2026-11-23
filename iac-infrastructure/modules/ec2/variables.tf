variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "app_subnet_ids" {
  description = "Podsieci aplikacyjne wg litery strefy, np. { a = ..., b = ... }"
  type        = map(string)
}

variable "security_group_id" {
  type = string
}

variable "eic_security_group_id" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "deploy_bucket" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}