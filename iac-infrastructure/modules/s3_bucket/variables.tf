variable "bucket_name" {
  type = string
}

variable "versioning" {
  type    = bool
  default = false
}

variable "noncurrent_expiration_days" {
  description = "Po ilu dniach usuwać nieaktualne wersje (null = nie usuwaj)"
  type        = number
  default     = null
}

variable "expiration_days" {
  description = "Po ilu dniach usuwać obiekty (null = nie usuwaj)"
  type        = number
  default     = null
}

variable "force_destroy" {
  type    = bool
  default = false
}

variable "extra_policy_json" {
  description = "Dodatkowa polityka bucketa (JSON) scalana z wymaganiem HTTPS"
  type        = string
  default     = null
}