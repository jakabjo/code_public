resource "azurerm_storage_account" "sa" {
  name                     = "${replace(var.name, "-", "")}funcsa"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  allow_blob_public_access = false
  enable_https_traffic_only = true
  tags = var.tags
}

resource "azurerm_service_plan" "plan" {
  name                = "${var.name}-plan"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption
  tags                = var.tags
}

resource "azurerm_linux_function_app" "func" {
  name                       = "${var.name}-app"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  service_plan_id            = azurerm_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  site_config {
    application_stack {
      python_version = "3.11"
    }
    use_32_bit_worker = false
  }
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "python"
    WEBSITE_RUN_FROM_PACKAGE = var.zip_path
  }
  tags = var.tags
}

output "function_default_hostname" { value = azurerm_linux_function_app.func.default_hostname }
