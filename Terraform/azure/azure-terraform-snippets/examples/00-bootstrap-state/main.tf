locals {
  name = "tfstate"
  tags = { Project = "tf-state-bootstrap" }
}

variable "resource_group_name" { type = string default = "rg-tfstate" }
variable "location"           { type = string default = "westus2" }
variable "storage_account_name" { type = string default = "tfstateacctdemo1234" }
variable "container_name" { type = string default = "tfstate" }

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "sa" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  allow_blob_public_access = false
  enable_https_traffic_only = true
  tags = local.tags
}

resource "azurerm_storage_container" "c" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

output "resource_group_name"  { value = azurerm_resource_group.rg.name }
output "storage_account_name" { value = azurerm_storage_account.sa.name }
output "container_name"       { value = azurerm_storage_container.c.name }
