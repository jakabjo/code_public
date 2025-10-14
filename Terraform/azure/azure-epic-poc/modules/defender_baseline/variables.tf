variable "rg_names" {
  type = list(string)
}

variable "enable_plan_vm" {
  type    = bool
  default = true
}

variable "enable_plan_sql" {
  type    = bool
  default = false
}
