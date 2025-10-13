variable "prefix"   { type = string }
variable "location" { type = string }
variable "tags"     { type = map(string) }

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "hub" {
  name     = "${var.prefix}-hub-rg"
  location = var.location
  tags     = var.tags
}

resource "azurerm_resource_group" "spoke" {
  name     = "${var.prefix}-spoke-rg"
  location = var.location
  tags     = var.tags
}

resource "random_string" "kv" { length = 5 upper = false special = false }

resource "azurerm_key_vault" "kv" {
  name                       = replace("${var.prefix}kv${random_string.kv.result}", "-", "")
  resource_group_name        = azurerm_resource_group.hub.name
  location                   = var.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = true
  soft_delete_retention_days = 7
  tags                       = var.tags
}

output "rg_hub_name"   { value = azurerm_resource_group.hub.name }
output "rg_spoke_name" { value = azurerm_resource_group.spoke.name }
output "kv_id"         { value = azurerm_key_vault.kv.id }
