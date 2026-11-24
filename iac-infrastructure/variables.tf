variable "project" {
  type    = string
  default = "bsiaw"
}

variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "domain_name" {
  description = "Zarejestrowana domena (strefa hostowana istnieje w Route 53)"
  type        = string
}

variable "app_version" {
  description = "Wersja obrazu aplikacji (nazwa archiwum w S3)"
  type        = string
  default     = "v1"
}


variable "enable_nat" {
  description = "Tymczasowy NAT Gateway i ruch wychodzący z EC2 (domyślnie wyłączony)"
  type        = bool
  default     = false
}

variable "waf_block" {
  description = "false = reguły WAF w trybie Count, true = Block"
  type        = bool
  default     = false
}

variable "rate_limited_paths" {
  description = "Ścieżki objęte limitem żądań (co najmniej 2)"
  type        = list(string)
  default     = ["/login/", "/register/", "/password-reset/", "/admin/login/"]
}

variable "rate_limit" {
  description = "Maksymalna liczba żądań z jednego IP w 5 minut na ścieżki z listy"
  type        = number
  default     = 30
}