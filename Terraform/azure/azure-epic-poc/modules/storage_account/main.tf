resource "random_string" "suffix" {
  length  = 5
  lower   = true
  upper   = false
  numeric = true
  special = false
}

locals {
  # Make an alphanumeric, lowercase, <=24 char name
  sa_base = lower(regexreplace("${var.name_prefix}sa${random_string.suffix.result}", "[^a-z0-9]", ""))
  sa_name = substr(local.sa_base, 0, 24)
}

resource "azurerm_storage_account" "sa" {
  name                          = local.sa_name
  resource_group_name           = var.rg_name
  location                      = var.location

  # Broad feature support (private endpoints, lifecycle, etc.)
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  account_kind                  = "StorageV2"

 # Secure baseline storage settings
# Valid for Standard_LRS and Premium BlockBlob/FileStorage

allow_blob_public_access       = var.allow_blob_public
min_tls_version                = var.min_tls
enable_https_traffic_only      = true
public_network_access_enabled  = "Disabled"   # enum expected, not bool
large_file_share_enabled       = false
shared_access_key_enabled      = true
infrastructure_encryption_enabled = true      # adds server-side encryption

network_rules {
  default_action             = "Deny"
  bypass                     = ["AzureServices"]
  virtual_network_subnet_ids = [var.vnet_subnet_id]
}


  tags = var.tags
}

# Private endpoint for Blob
resource "azurerm_private_endpoint" "pe_blob" {
  name                = "${var.name_prefix}-pe-blob"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.vnet_subnet_id

  private_service_connection {
    name                           = "blob"
    private_connection_resource_id = azurerm_storage_account.sa.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  tags = var.tags
}

# Attach the correct Private DNS zone to the Private Endpoint
resource "azurerm_private_dns_zone_group" "pe_blob_dns" {
  name                 = "${var.name_prefix}-pdzg-blob"
  private_endpoint_id  = azurerm_private_endpoint.pe_blob.id

  private_dns_zone_configs {
    name                 = "blob"
    private_dns_zone_id  = var.private_dns_zone_ids["privatelink.blob.core.windows.net"]
  }
}
