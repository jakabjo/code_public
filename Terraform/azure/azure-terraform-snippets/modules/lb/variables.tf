variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "subnet_id" { type = string }
variable "backend_ip_config_names" {
  type        = list(string)
  default     = []
  description = "Optional NIC IP config names to register (example composition)."
}
variable "tags" { type = map(string) default = {} }
