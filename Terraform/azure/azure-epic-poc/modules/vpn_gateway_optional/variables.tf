variable "rg_name"      { type = string }
variable "location"     { type = string }
variable "name_prefix"  { type = string }
variable "vnet_id"      { type = string }
variable "gw_subnet_id" { type = string }
variable "sku"          { type = string, default = "VpnGw2" }
variable "tags"         { type = map(string) }
