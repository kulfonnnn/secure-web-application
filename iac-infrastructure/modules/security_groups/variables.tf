variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "allow_internet_egress" {
  description = "Tymczasowy ruch wychodzący HTTP/HTTPS z EC2 (na czas pracy NAT Gateway)"
  type        = bool
  default     = false
}