variable "prefix"    { type = string }
variable "location"  { type = string }
variable "rg_name"   { type = string }
variable "target_ids"{ type = list(string) }
variable "tags"      { type = map(string) }

resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.prefix}-law"
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "diag" {
  for_each                   = toset(var.target_ids)
  name                       = "${var.prefix}-diag-${substr(sha1(each.value), 0, 6)}"
  target_resource_id         = each.value
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  metric { category = "AllMetrics" enabled = true }
}

output "law_id" { value = azurerm_log_analytics_workspace.law.id }
