locals {
  name = "demo"
  tags = { Project = "azure-tf-snippets", Env = "dev" }
}

variable "location" { type = string default = "westus2" }
variable "admin_login" { type = string default = "sqladminuser" }
variable "admin_password" { type = string default = "ChangeMe123!" }
variable "db_name" { type = string default = "appdb" }

module "rg" {
  source   = "../../modules/rg"
  name     = "rg-${local.name}"
  location = var.location
  tags     = local.tags
}

module "sql" {
  source              = "../../modules/sql-database"
  name                = "sql-${local.name}-srv"
  resource_group_name = module.rg.name
  location            = module.rg.location
  admin_login         = var.admin_login
  admin_password      = var.admin_password
  db_name             = var.db_name
  tags                = local.tags
}

output "sql_fqdn" { value = module.sql.fqdn }
