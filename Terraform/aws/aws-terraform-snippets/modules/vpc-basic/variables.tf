variable "name"      { type = string }
variable "cidr"      { type = string }
variable "az_count"  { type = number  default = 2 }
variable "create_nat_gw" { type = bool default = true }
variable "tags"      { type = map(string) default = {} }
