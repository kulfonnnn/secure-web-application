variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "alert_email" {
  type = string
}

variable "instance_ids" {
  type = map(string)
}

variable "db_instance_id" {
  type = string
}

variable "alb_arn_suffix" {
  type = string
}

variable "target_group_arn_suffix" {
  type = string
}

variable "cache_cluster_id" {
  type = string
}