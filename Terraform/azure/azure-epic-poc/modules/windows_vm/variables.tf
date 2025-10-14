variable "rg_name"           { type = string }
variable "location"          { type = string }
variable "name_prefix"       { type = string }
variable "subnet_id"         { type = string }
variable "admin_username"    { type = string }
variable "admin_password"    { type = string, sensitive = true }
variable "size"              { type = string }
variable "enable_ultra_disk" { type = bool, default = true }
variable "data_disks" {
  type = list(object({
    size_gb = number
    sku     = string
    lun     = number
  }))
}
variable "log_analytics_id"  { type = string }
variable "tags"              { type = map(string) }
