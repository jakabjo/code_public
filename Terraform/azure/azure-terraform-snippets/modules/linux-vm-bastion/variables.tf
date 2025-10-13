variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "subnet_id" { type = string }
variable "admin_username" { type = string }
variable "ssh_public_key" { type = string }
variable "vm_size" { type = string default = "Standard_B1ms" }
variable "tags" { type = map(string) default = {} }
