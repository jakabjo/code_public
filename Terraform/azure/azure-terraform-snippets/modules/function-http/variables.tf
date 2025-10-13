variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "zip_path" { type = string }
variable "tags" { type = map(string) default = {} }
