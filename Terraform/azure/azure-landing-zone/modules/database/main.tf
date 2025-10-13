variable "prefix"    { type = string }
variable "location"  { type = string }
variable "rg_name"   { type = string }
variable "subnet_id" { type = string }
variable "tags"      { type = map(string) }

resource "random_string" "pg" { length = 6 upper = false special = false }
resource "random_password" "pg" { length = 20 special = true }

resource "azurerm_private_dns_zone" "pg" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.rg_name
  tags                = var.tags
}

# For simplicity we link VNet via subnet's VNet ID derived from subnet_id
locals {
  vnet_id = regex("(.+)/subnets/.+", var.subnet_id)
}

resource "azurerm_private_dns_zone_virtual_network_link" "pg_link" {
  name                  = "${var.prefix}-pg-link"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.pg.name
  virtual_network_id    = local.vnet_id
  registration_enabled  = false
}

resource "azurerm_postgresql_flexible_server" "pg" {
  name                   = "${var.prefix}-pg${random_string.pg.result}"
  location               = var.location
  resource_group_name    = var.rg_name
  version                = "16"
  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768
  backup_retention_days  = 7
  zone                   = "1"

  delegated_subnet_id    = var.subnet_id
  private_dns_zone_id    = azurerm_private_dns_zone.pg.id

  authentication { active_directory_auth_enabled=false password_auth_enabled=true }

  administrator_login    = "pgadmin"
  administrator_password = random_password.pg.result

  tags = var.tags
}

output "fqdn" { value = azurerm_postgresql_flexible_server.pg.fqdn }
