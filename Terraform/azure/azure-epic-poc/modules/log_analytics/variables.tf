variable "rg_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "retention_in_days" {
  type    = number
  default = 60
}

variable "tags" {
  type = map(string)
}

