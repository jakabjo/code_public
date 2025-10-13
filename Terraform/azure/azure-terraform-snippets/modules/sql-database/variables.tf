variable "name" { type = string } # server name
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "admin_login" { type = string }
variable "admin_password" { type = string sensitive = true }
variable "db_name" { type = string }
variable "min_tls_version" { type = string default = "1.2" }
variable "tags" { type = map(string) default = {} }
