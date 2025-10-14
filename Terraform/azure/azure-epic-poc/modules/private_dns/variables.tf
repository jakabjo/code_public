variable "rg_name"     { type = string }
variable "name_prefix" { type = string }
variable "vnet_id"     { type = string }
variable "zones"       { type = list(string) }
variable "tags"        { type = map(string) }
