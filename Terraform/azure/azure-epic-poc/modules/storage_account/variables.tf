variable "rg_name"              { type = string }
variable "location"             { type = string }
variable "name_prefix"          { type = string }
variable "vnet_subnet_id"       { type = string }
variable "private_dns_zone_ids" { type = map(string) }
variable "allow_blob_public"    { type = bool, default = false }
variable "min_tls"              { type = string, default = "TLS1_2" }
variable "tags"                 { type = map(string) }
