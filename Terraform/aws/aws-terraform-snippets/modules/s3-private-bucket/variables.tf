variable "name" { type = string }
variable "versioning" { type = bool default = true }
variable "lifecycle_days" { type = number default = 30 }
variable "tags" { type = map(string) default = {} }
