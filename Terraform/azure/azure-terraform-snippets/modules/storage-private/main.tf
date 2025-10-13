resource "azurerm_storage_account" "sa" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.replication_type
  min_tls_version          = "TLS1_2"
  allow_blob_public_access = false
  enable_https_traffic_only = true
  tags = var.tags
}

output "id"   { value = azurerm_storage_account.sa.id }
output "name" { value = azurerm_storage_account.sa.name }
