variable "name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_id" { type = string }
variable "ssh_cidr" { type = string description = "CIDR allowed to SSH in" }
variable "instance_type" { type = string default = "t3.micro" }
variable "key_name" { type = string }
variable "tags" { type = map(string) default = {} }
