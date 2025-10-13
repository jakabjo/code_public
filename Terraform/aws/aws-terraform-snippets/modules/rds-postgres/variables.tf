variable "name" { type = string }
variable "subnet_ids" { type = list(string) }
variable "vpc_security_group_ids" { type = list(string) }
variable "username" { type = string }
variable "password" { type = string sensitive = true }
variable "engine_version" { type = string default = "16.2" }
variable "instance_class" { type = string default = "db.t4g.micro" }
variable "publicly_accessible" { type = bool default = false }
variable "allocated_storage" { type = number default = 20 }
variable "tags" { type = map(string) default = {} }
