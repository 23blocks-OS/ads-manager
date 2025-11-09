variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "redis_security_group_id" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "database_name" {
  type = string
}

variable "database_username" {
  type      = string
  sensitive = true
}

variable "database_password" {
  type      = string
  sensitive = true
}

variable "redis_node_type" {
  type = string
}

variable "redis_auth_token" {
  type      = string
  sensitive = true
}
