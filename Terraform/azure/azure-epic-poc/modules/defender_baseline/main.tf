# Example: enable Microsoft Defender for Cloud plans at subscription scope
resource "azurerm_security_center_subscription_pricing" "vm" {
  tier          = var.enable_plan_vm ? "Standard" : "Free"
  resource_type = "VirtualMachines"
}

resource "azurerm_security_center_subscription_pricing" "sql" {
  tier          = var.enable_plan_sql ? "Standard" : "Free"
  resource_type = "SqlServers"
}
