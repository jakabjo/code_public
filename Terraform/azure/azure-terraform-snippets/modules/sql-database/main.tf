resource "azurerm_mssql_server" "server" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.admin_login
  administrator_login_password = var.admin_password
  minimum_tls_version          = var.min_tls_version
  public_network_access_enabled = true
  tags = var.tags
}

resource "azurerm_mssql_database" "db" {
  name           = var.db_name
  server_id      = azurerm_mssql_server.server.id
  sku_name       = "Basic"
  max_size_gb    = 2
  zone_redundant = false
  tags = var.tags
}

output "fqdn" { value = azurerm_mssql_server.server.fully_qualified_domain_name }
output "database_id" { value = azurerm_mssql_database.db.id }
