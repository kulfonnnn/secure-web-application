variable "project" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "subnets" {
  description = "Podsieci: nazwa => zakres CIDR, litera strefy i warstwa (public/app/data)"
  type = map(object({
    cidr = string
    az   = string
    tier = string
  }))
}

variable "enable_nat" {
  description = "Tymczasowy NAT Gateway (aktualizacje instancji)"
  type        = bool
  default     = false
}