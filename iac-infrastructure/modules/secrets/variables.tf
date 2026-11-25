variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "secret_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "endpoint_subnet_id" {
  type = string
}

variable "endpoint_security_group_id" {
  type = string
}

variable "enable_endpoint" {
  type    = bool
  default = true
}