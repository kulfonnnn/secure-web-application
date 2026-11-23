variable "project" {
  type = string
}

variable "subnet_ids" {
  description = "Podsieci danych z co najmniej dwóch stref"
  type        = list(string)
}

variable "security_group_id" {
  type = string
}

variable "db_name" {
  type    = string
  default = "web_security_db"
}

variable "username" {
  type    = string
  default = "web_security_user"
}

variable "password" {
  type      = string
  sensitive = true
}


variable "availability_zone" {
  type = string
}