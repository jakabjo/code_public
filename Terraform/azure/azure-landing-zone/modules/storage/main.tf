variable "prefix"   { type = string }
variable "location" { type = string }
variable "rg_name"  { type = string }
variable "tags"     { type = map(string) }

resource "random_string" "sa" { length = 6 upper = false special = false }

resource "azurerm_storage_account" "sa" {
  name                     = replace("${var.prefix}sa${random_string.sa.result}", "-", "")
  location                 = var.location
  resource_group_name      = var.rg_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  public_network_access_enabled = false
  tags = var.tags
}

resource "azurerm_storage_container" "logs" {
  name                  = "logs"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

output "storage_account_id" { value = azurerm_storage_account.sa.id }
